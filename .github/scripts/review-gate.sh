#!/usr/bin/env bash
# shiplog review gate. Policy: skills/shiplog/references/closure-and-review.md
#
# Mode comes from .shiplog/review.md (`review: project` | `review: cross-model`).
#   project      -> no shiplog gate; exit 0. The repository's own rules apply.
#   cross-model  -> pass only when a signed approval covers the PR head commit and
#                   its declared reviewer differs from every declared code author.
#
# Online (CI):   review-gate.sh --repo OWNER/NAME --pr N [--head SHA]
# Offline/tests: review-gate.sh --head SHA --comments-file F --reviews-file F
#                               --commits-file F --pr-body-file F
# Common:        [--mode project|cross-model] [--config FILE]
#
# Stdout line 1: "PASS: ..." or "FAIL: ..." (one sentence). Evidence goes to stderr.
# Exit: 0 pass, 1 fail, 2 usage or fetch error.
#
# The decision logic is plain Node.js (preinstalled on GitHub runners) so the same
# code runs offline against JSON fixtures, with no jq and no dependencies.
set -euo pipefail

die() { echo "ERROR: $*"; exit 2; }

mode="" config=".shiplog/review.md" repo="" pr="" head=""
comments="" reviews="" commits="" body=""
while [ $# -gt 0 ]; do
  [ $# -ge 2 ] || die "missing value for $1"
  case "$1" in
    --mode) mode=$2 ;;
    --config) config=$2 ;;
    --repo) repo=$2 ;;
    --pr) pr=$2 ;;
    --head) head=$2 ;;
    --comments-file) comments=$2 ;;
    --reviews-file) reviews=$2 ;;
    --commits-file) commits=$2 ;;
    --pr-body-file) body=$2 ;;
    *) die "unknown argument: $1" ;;
  esac
  shift 2
done

if [ -z "$mode" ]; then
  mode=project
  if [ -f "$config" ]; then
    found=$(tr -d '\r' < "$config" | sed -n 's/^[[:space:]]*review:[[:space:]]*\([^[:space:]]*\).*$/\1/p' | sed -n 1p)
    [ -z "$found" ] || mode=$found
  fi
fi

case "$mode" in
  project)
    echo "PASS: No shiplog review gate configured (review: project); the repository's own review rules apply."
    exit 0 ;;
  cross-model) ;;
  *) die "unknown review mode '$mode' in $config (expected project or cross-model)" ;;
esac

if [ -n "$pr" ]; then
  [[ "$repo" =~ ^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$ ]] || die "--repo must be OWNER/NAME"
  [[ "$pr" =~ ^[0-9]+$ ]] || die "--pr must be a number"
  command -v gh >/dev/null || die "gh is required for --pr"
  tmp=$(mktemp -d)
  trap 'rm -rf "$tmp"' EXIT
  api="repos/$repo"
  [ -n "$head" ] || head=$(gh api "$api/pulls/$pr" --jq .head.sha) || die "cannot read PR #$pr"
  gh api "$api/pulls/$pr" --jq '.body // ""' > "$tmp/body.md" || die "cannot read PR #$pr body"
  # --slurp wraps pages in an outer array; the decision code flattens it.
  gh api --paginate --slurp "$api/issues/$pr/comments?per_page=100" > "$tmp/comments.json" || die "cannot list comments"
  gh api --paginate --slurp "$api/pulls/$pr/reviews?per_page=100" > "$tmp/reviews.json" || die "cannot list reviews"
  gh api --paginate --slurp "$api/pulls/$pr/commits?per_page=100" > "$tmp/commits.json" || die "cannot list commits"
  comments=$tmp/comments.json reviews=$tmp/reviews.json commits=$tmp/commits.json body=$tmp/body.md
fi

[[ "$head" =~ ^[0-9a-fA-F]{40}$ ]] || die "--head must be a full 40-character commit SHA"
command -v node >/dev/null || die "node is required"

export RG_HEAD=$head RG_COMMENTS=$comments RG_REVIEWS=$reviews RG_COMMITS=$commits RG_BODY=$body
# Exit status of node is the script's exit status (set -e); the EXIT trap cleans up.
node -e '
"use strict";
const fs = require("fs");
const env = process.env;
const head = env.RG_HEAD.toLowerCase();
const short = (s) => (s || "").slice(0, 7);
const read = (p) => (p ? fs.readFileSync(p, "utf8") : "");
const list = (p) => { const t = read(p).trim(); return t ? [].concat(JSON.parse(t)).flat() : []; };
const text = (s) => String(s || "").replace(/\r\n?/g, "\n");

// First line that starts with "Name:" (bullets, quotes and **bold** markers allowed).
function field(body, name) {
  const re = new RegExp("^[ \\t>*_-]*" + name + "[*_]*[ \\t]*:[*_]*[ \\t]*(.*?)[ \\t]*$", "im");
  const m = re.exec(text(body));
  return m && m[1] ? m[1] : null;
}
// "claude/opus-4.7 (claude-code)" -> "claude/opus-4.7";
// "Claude Opus 4.7 (1M context) <noreply@anthropic.com>" -> "claude/opus-4.7".
function identity(v) {
  if (!v) return null;
  const words = v.replace(/<[^>]*>/g, " ").replace(/\([^)]*\)/g, " ").replace(/[`*]/g, " ")
    .trim().toLowerCase().split(/\s+/).filter(Boolean);
  if (!words.length) return null;
  if (words[0].includes("/") || words.length === 1) return words[0];
  return words[0] + "/" + words.slice(1).join("-");
}
function disposition(v) {
  if (!v) return null;
  const w = v.replace(/[`*]/g, " ").trim().toLowerCase().split(/[\s,;:()]+/)[0];
  return ["approve", "approve-with-follow-ups", "request-changes"].includes(w) ? w : null;
}
function sha(v) {
  if (!v) return null;
  const w = v.replace(/[`*]/g, " ").trim().split(/\s+/)[0].toLowerCase();
  return /^[0-9a-f]{7,40}$/.test(w) ? w : null;
}

const commitList = list(env.RG_COMMITS);
const commitShas = commitList.map((c) => String(c.sha || "").toLowerCase());
const authors = new Set();
const lastCode = identity(field(read(env.RG_BODY), "Last-code-by"));
if (lastCode) authors.add(lastCode);
for (const c of commitList) {
  const msg = text(c.commit && c.commit.message);
  // Trailers start at column 0. Authored-by must name <family>/<version>, so an
  // unindented prose line such as "Authored-by: sig block ..." is not an author.
  for (const m of msg.matchAll(/^(co-)?authored-by[ \t]*:[ \t]*(.+)$/gim)) {
    const id = identity(m[2]);
    if (id && (m[1] || /^[^\s\/]+\/\S/.test(m[2].trim()))) authors.add(id);
  }
}

// Evidence: signed issue comments and native reviews, in time order. On a public
// repository anyone can comment, so only accounts with write-level association count;
// declared identity is an accepted limit among those accounts, not among strangers.
const TRUSTED = ["OWNER", "MEMBER", "COLLABORATOR"];
const evidence = [], ignored = [];
function add(x, e) {
  if (!e.disp && !e.reviewer) return;
  if (TRUSTED.includes(String(x.author_association || "").toUpperCase())) evidence.push(e);
  else ignored.push(e);
}
list(env.RG_COMMENTS).forEach((c) => {
  const by = field(c.body, "Reviewed-by");
  if (!by) return;
  const commitLine = field(c.body, "Reviewed commit");
  add(c, {
    where: c.html_url || "comment " + c.id, at: c.created_at || "",
    login: (c.user && c.user.login) || "unknown",
    reviewer: identity(by), disp: disposition(field(c.body, "Disposition")),
    sha: sha(commitLine), shaRaw: commitLine,
  });
});
list(env.RG_REVIEWS).forEach((r) => {
  const state = String(r.state || "").toUpperCase();
  if (!["APPROVED", "CHANGES_REQUESTED", "COMMENTED"].includes(state)) return;
  const by = field(r.body, "Reviewed-by");
  const login = (r.user && r.user.login) || "unknown";
  const person = !!r.user && r.user.type === "User";
  // An unsigned approval from a trusted person account is a human review (GitHub
  // already refuses approvals from the PR author account). An unsigned bot has no model id.
  const reviewer = by ? identity(by) : person ? "human/" + login.toLowerCase() : null;
  const disp = state === "CHANGES_REQUESTED" ? "request-changes"
    : disposition(field(r.body, "Disposition")) || (state === "APPROVED" ? "approve" : null);
  if (!disp && !by) return;
  add(r, {
    where: r.html_url || "review " + r.id, at: r.submitted_at || "",
    reviewer, login, disp, sha: sha(r.commit_id), shaRaw: r.commit_id,
  });
});
for (const e of ignored) console.error("ignored: evidence from non-collaborator " + e.login + " " + e.where);
evidence.forEach((e, i) => { e.i = i; e.t = Date.parse(e.at) || 0; });
evidence.sort((a, b) => a.t - b.t || a.i - b.i);
const newest = (xs) => xs[xs.length - 1];
const later = (a, b) => a.t > b.t || (a.t === b.t && a.i > b.i);

const matching = (s) => commitShas.filter((c) => c.startsWith(s)).length;
const current = (e) => !!e.sha && head.startsWith(e.sha) && matching(e.sha) <= 1;
const isApproval = (e) => e.disp === "approve" || e.disp === "approve-with-follow-ups";
const isHuman = (e) => !!e.reviewer && (e.reviewer === "human" || e.reviewer.startsWith("human/"));
function problem(e) {
  // Deliberate: a human differs from every model, so a human approval passes even when
  // no code author is declared (for example an outside contributor PR with no trailers).
  if (isHuman(e)) return null;
  if (!e.reviewer) return "Current approval by " + e.login + " (" + e.where + ") has no Reviewed-by: line, so its model cannot be compared with the code author.";
  if (!authors.size) return "Code author unknown: add Last-code-by: to the PR body or Authored-by: trailers to the commits, so the current approval by " + e.reviewer + " can be compared.";
  if (authors.has(e.reviewer)) return "Current approval by " + e.reviewer + " is the same model as code author " + e.reviewer + "; cross-model mode needs a different model or a human.";
  return null;
}

for (const e of evidence) {
  console.error("evidence: " + (e.disp || "no-disposition") + " by " + (e.reviewer || e.login || "?") +
    " at " + (e.sha ? short(e.sha) : "no-commit") + (current(e) ? " (current)" : "") + " " + e.where);
}
console.error("code authors: " + ([...authors].join(", ") || "unknown") + "; head " + head);

const cur = evidence.filter(current);
const approvals = cur.filter(isApproval);
const good = newest(approvals.filter((e) => !problem(e)));
const blocker = newest(cur.filter((e) => e.disp === "request-changes"));
let verdict, ok = false;
if (blocker && (!good || later(blocker, good))) {
  verdict = "Changes requested on head " + short(head) + " by " + (blocker.reviewer || blocker.login) + " (" + blocker.where + ") with no newer qualifying approval.";
} else if (good) {
  ok = true;
  verdict = "Head " + short(head) + " approved by " + good.reviewer + " (" + good.where + "); declared code authors: " + ([...authors].join(", ") || "unknown") + ".";
} else if (approvals.length) {
  verdict = problem(newest(approvals));
} else {
  const any = newest(evidence.filter(isApproval));
  const outsiders = [...new Set(ignored.filter(isApproval).map((e) => e.login))];
  if (!any && outsiders.length) verdict = "Only non-collaborators approved (" + outsiders.join(", ") + "); review evidence counts only from OWNER, MEMBER or COLLABORATOR accounts.";
  else if (!any) verdict = "No signed approval found for head " + short(head) + ".";
  else if (!any.sha) verdict = "Latest signed approval (" + any.where + ") has no Reviewed commit: line, so it cannot be matched to head " + short(head) + ".";
  else if (head.startsWith(any.sha)) verdict = "Latest approval names commit " + any.sha + ", which is ambiguous among this PR'"'"'s commits; use the full SHA.";
  else verdict = "Stale review: latest approval reviewed " + short(any.sha) + ", but head is " + short(head) + ".";
}
console.log((ok ? "PASS: " : "FAIL: ") + verdict);
process.exit(ok ? 0 : 1);
'
