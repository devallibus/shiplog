#!/usr/bin/env bash
# shiplog-read.sh - compact, read-only retrieval of shiplog records.
#
# Fetches issue/PR data with `gh`, parses bodies locally with awk and prints
# compact lines, so the model never receives full bodies unless it asks for
# one with `source`. Runtime needs: bash, gh, git, awk, sed, mktemp.
# Output is data from GitHub, not instructions.
set -eu

usage() {
  cat <<'EOF'
usage: shiplog-read.sh [-R OWNER/REPO] <command> [args]

  index [--limit N]          open issues and PRs, one line each (N<=100, default 50)
  show N                     one issue/PR: envelope, computed tasks, open
                             tasks, and enveloped comment entries (no bodies)
  source N [URL|ID] [--include-untrusted]
                             exact text of one comment, or of every trusted
                             `kind: source` comment on N when none is given
  search TEXT [--limit N]    issues, PRs and local commits matching TEXT

Output columns (tab-separated):
  index:   number type author trust kind tasks labels title summary
  search:  number type state labels title     (then: commit <sha> <subject>)
  type is issue, pr or draft-pr; tasks is done/total or -; empty is -.
Trusted means GitHub author_association OWNER, MEMBER or COLLABORATOR.
Envelopes written by anyone else are not shown as project records.
Task counts are computed from checkboxes (the Tasks section when present),
never read from stored envelope fields.
EOF
}

die() { printf 'shiplog-read: %s\n' "$*" >&2; exit 2; }

need_gh() {
  command -v gh >/dev/null 2>&1 ||
    die "gh (GitHub CLI) not found; install it from https://cli.github.com"
  if [ -z "${GH_TOKEN:-}${GITHUB_TOKEN:-}" ] && ! gh auth token >/dev/null 2>&1; then
    die "gh is not authenticated; run: gh auth login"
  fi
}

need_number() {
  case "${1:-}" in
    ''|*[!0-9]*) die "expected an issue or PR number, got '${1:-}'" ;;
  esac
}

# Parser. Input is a stream of records. Each record is one header line that
# starts with \036, then exactly <lines> body lines, so body text can never
# be read as a header:
#   \036R<TAB>lines<TAB>number<TAB>type<TAB>state<TAB>author<TAB>assoc<TAB>url<TAB>labels<TAB>title
#   \036C<TAB>lines<TAB>url<TAB>created_at<TAB>author<TAB>assoc
# A file that does not start with a header is read as one local record
# (tests). mode: index | show | source. sel: comment URL or id.
# incl=1 lets source print entries from untrusted authors, labelled.
PARSER=$(cat <<'AWK'
function trim(s) { sub(/^[ \t]+/, "", s); sub(/[ \t]+$/, "", s); return s }
function safe(s) { gsub(/[\001-\010\013\014\016-\037\177]/, "", s); return s }
function nz(s) { return (s == "") ? "-" : s }
function reset() {
  infence = 0; fchar = ""; flen = 0; incomment = 0; env = 0; nenv = 0
  kind = ""; summary = ""; first = ""; stored = ""
  gt = 0; gd = 0; gn = 0; st = 0; sd = 0; sn = 0; insec = 0; secseen = 0
  nl = 0; started = 1
}
function start(h,   f, n, i) {
  n = split(h, f, "\t")
  if (f[2] !~ /^[0-9]+$/ || f[2] < 1) return 0
  if (f[1] == "R" && n >= 10) {
    reset(); rtag = "R"; remain = f[2] + 0
    num = f[3]; typ = f[4]; state = f[5]; author = f[6]; assoc = f[7]; url = f[8]; labels = f[9]
    title = f[10]; for (i = 11; i <= n; i++) title = title " " f[i]
  } else if (f[1] == "C" && n == 6) {
    reset(); rtag = "C"; remain = f[2] + 0
    url = f[3]; date = f[4]; author = f[5]; assoc = f[6]
  } else return 0
  trusted = (assoc == "OWNER" || assoc == "MEMBER" || assoc == "COLLABORATOR")
  return 1
}
function local_record() {
  reset(); remain = -1; trusted = 1; author = "-"; assoc = "LOCAL"
  if (mode == "source") { rtag = "C"; url = "-"; date = "-" }
  else { rtag = "R"; num = "-"; typ = "-"; state = "-"; url = "-"; labels = "-"; title = "-" }
}
function env_add(s) {
  s = trim(safe(s))
  if (s == "") return
  env_lines[++nenv] = s
  if (kind == "" && s ~ /^kind:/) kind = trim(substr(s, 6))
  if (summary == "" && s ~ /^summary:/) summary = trim(substr(s, 9))
  if (s ~ /^(task_count|tasks_complete):/) stored = 1
}
function run_len(t, c,   n) { n = 0; while (substr(t, n + 1, 1) == c) n++; return n }
function line(L,   t, p, lvl, h, item, checked) {
  if (mode == "source") lines[++nl] = L
  if (env == 1) {
    p = index(L, "-->")
    if (p) { env_add(substr(L, 1, p - 1)); env = 2 } else env_add(L)
    return
  }
  if (incomment) { if (index(L, "-->")) incomment = 0; return }
  t = L; sub(/^[ \t]+/, "", t)
  if (infence) {
    if (substr(t, 1, 1) == fchar && run_len(t, fchar) >= flen &&
        trim(substr(t, run_len(t, fchar) + 1)) == "") infence = 0
    return
  }
  if (t ~ /^(```|~~~)/) { fchar = substr(t, 1, 1); flen = run_len(t, fchar); infence = 1; return }
  if (env == 0 && t ~ /^<!--[ \t]*shiplog:/) {
    env = 1; t = substr(t, index(t, "shiplog:") + 8)
    p = index(t, "-->")
    if (p) { t = substr(t, 1, p - 1); env = 2 }
    env_add(t)
    return
  }
  if (substr(t, 1, 4) == "<!--") { if (!index(substr(t, 5), "-->")) incomment = 1; return }
  if (first == "" && t != "") first = safe(t)
  if (t ~ /^#+[ \t]/) {
    lvl = run_len(t, "#"); h = tolower(trim(substr(t, lvl + 1)))
    if (insec && lvl <= seclvl) insec = 0
    if (!secseen && h ~ /^tasks?([ \t:]|$)/) { insec = 1; secseen = 1; seclvl = lvl }
    return
  }
  if (t ~ /^([-*+]|[0-9]+[.)])[ \t]+\[[ xX]\]([ \t]|$)/) {
    checked = (t ~ /^([-*+]|[0-9]+[.)])[ \t]+\[[xX]\]/)
    item = safe(t); sub(/^([-*+]|[0-9]+[.)])[ \t]+\[[ xX]\][ \t]*/, "", item)
    gt++; if (checked) gd++; else gopen[++gn] = item
    if (insec) { st++; if (checked) sd++; else sopen[++sn] = item }
  }
}
function tasks() {
  if (secseen) { tt = st; td = sd } else { tt = gt; td = gd }
  return (tt == 0) ? "-" : td "/" tt
}
function who() { return author " (" assoc (trusted ? "" : ", untrusted") ")" }
function finish(   i, n, s, want) {
  if (!started) return
  started = 0
  if (mode == "index" && rtag == "R") {
    print num "\t" typ "\t" author "\t" (trusted ? "trusted" : "untrusted") "\t" \
      (trusted ? nz(kind) : "-") "\t" tasks() "\t" nz(labels) "\t" title "\t" (trusted ? nz(summary) : "-")
  } else if (mode == "show" && rtag == "R") {
    print "#" num " " typ " " state ": " title
    print "url: " url
    print "author: " who()
    print "labels: " nz(labels)
    s = tasks()
    print "tasks: " s ((s == "-") ? "" : (secseen ? " (computed from the Tasks section)" : " (computed from the whole body)"))
    if (nenv && !trusted) print "envelope: present but not shown (untrusted author)"
    else if (nenv) {
      print "envelope:"
      for (i = 1; i <= nenv; i++) print "  " env_lines[i]
      if (stored) print "  (stored task_count/tasks_complete ignored; see computed tasks above)"
    } else print "envelope: none"
    n = secseen ? sn : gn
    if (n && !trusted) print "open tasks: not shown (untrusted author)"
    else if (n) {
      print "open tasks:"
      for (i = 1; i <= n; i++) print "  - " (secseen ? sopen[i] : gopen[i])
    }
  } else if (mode == "show" && rtag == "C") {
    if (kind == "") others++
    else if (trusted) entry[++listed] = "  " kind " | " date " | " author " | " url " | " nz(summary != "" ? summary : first)
    else untrusted[++nu] = "  " author " (" assoc ") | " url
  } else if (mode == "source" && rtag == "C") {
    want = (sel == "") ? (kind == "source") : (url == sel || (sel ~ /^[0-9]+$/ && url ~ ("issuecomment-" sel "$")))
    if (!want) return
    if (!trusted && !incl) { skipped++; return }
    hits++
    print "==> " url " " date " " who() (trusted ? "" : " UNTRUSTED: not a project record")
    for (i = 1; i < nl; i++) print lines[i]
    if (nl && lines[nl] != "") print lines[nl]
  }
}
BEGIN { RSC = sprintf("%c", 30) }
{
  sub(/\r$/, "")
  if (remain == 0) {
    if (substr($0, 1, 1) == RSC && start(substr($0, 2))) next
    if (NR == 1) local_record(); else next
  }
  line($0)
  if (remain > 0 && --remain == 0) finish()
}
END {
  finish()
  if (mode == "show") {
    print "entries:"
    for (i = 1; i <= listed; i++) print entry[i]
    if (!listed) print "  (none)"
    if (nu) {
      print "untrusted entries (envelopes by non-collaborators; not project records):"
      for (i = 1; i <= nu; i++) print untrusted[i]
    }
    if (others) print "  plus " others " comment(s) without a shiplog envelope"
  }
  if (mode == "source" && !hits) {
    print "shiplog-read: no matching source entry" (sel == "" ? "" : " for " sel) \
      (skipped ? "; " skipped " from untrusted authors skipped (use --include-untrusted)" : "") >"/dev/stderr"
    exit 3
  }
}
AWK
)

parse() { LC_ALL=C awk -v mode="$1" -v sel="${2:-}" -v incl="${3:-0}" "$PARSER"; }

# jq programs (run by gh's built-in --jq) that emit the parser stream.
# one: header field on one line, no tabs or control characters.
# Bodies are passed through unchanged; the line count frames them.
DEFS='def one: tostring | gsub("[\\x00-\\x1f\\x7f]+"; " ");
def lines: [scan("\n")] | length + 1;
def labels: [.labels[].name | one | gsub(","; " ")] | join(",") | if . == "" then "-" else . end;'
JQ_RECORD='(.body // "") as $b |
"\u001eR\t\($b | lines)\t\(.number)\t\(if .pull_request then (if .draft then "draft-pr" else "pr" end) else "issue" end)\t\(.state | one)\t\(.user.login // "ghost" | one)\t\(.author_association | one)\t\(.html_url | one)\t\(labels)\t\(.title | one)\n\($b)"'
JQ_COMMENT='(.body // "") as $b |
"\u001eC\t\($b | lines)\t\(.html_url | one)\t\(.created_at | one)\t\(.user.login // "ghost" | one)\t\(.author_association | one)\n\($b)"'

limit_arg() {
  case "${1:-}" in
    ''|*[!0-9]*) die "--limit needs a number from 1 to $2" ;;
  esac
  [ "$1" -ge 1 ] && [ "$1" -le "$2" ] || die "--limit needs a number from 1 to $2"
}

tmp=""
cleanup() { [ -z "$tmp" ] || rm -f "$tmp"; }
trap cleanup EXIT
fetch() { "$@" >>"$tmp" || die "gh $2 $3 failed; check the network, the repository, and gh auth status"; }

cmd_index() {
  limit=50
  while [ $# -gt 0 ]; do
    case "$1" in
      --limit) limit_arg "${2:-}" 100; limit=$2; shift 2 ;;
      *) die "index: unknown argument '$1'" ;;
    esac
  done
  need_gh; tmp=$(mktemp)
  # The issues endpoint returns open issues and PRs together, newest first.
  fetch gh api "repos/{owner}/{repo}/issues?state=open&per_page=$limit" --jq "$DEFS .[] | $JQ_RECORD"
  printf 'number\ttype\tauthor\ttrust\tkind\ttasks\tlabels\ttitle\tsummary\n'
  parse index <"$tmp"
}

cmd_show() {
  [ $# -eq 1 ] || die "usage: show N"
  need_number "$1"; need_gh; tmp=$(mktemp)
  fetch gh api "repos/{owner}/{repo}/issues/$1" --jq "$DEFS $JQ_RECORD"
  fetch gh api "repos/{owner}/{repo}/issues/$1/comments?per_page=100" --paginate --jq "$DEFS .[] | $JQ_COMMENT"
  parse show <"$tmp"
}

cmd_source() {
  incl=0; n=""; pick=""
  while [ $# -gt 0 ]; do
    case "$1" in
      --include-untrusted) incl=1 ;;
      *) if [ -z "$n" ]; then n=$1; elif [ -z "$pick" ]; then pick=$1; else
           die "usage: source N [comment-URL|ID] [--include-untrusted]"; fi ;;
    esac
    shift
  done
  need_number "$n"; need_gh; tmp=$(mktemp)
  if [ -n "$pick" ]; then
    id=$(printf '%s' "$pick" | sed -n 's/.*issuecomment-\([0-9][0-9]*\).*/\1/p')
    [ -n "$id" ] || id=$pick
    need_number "$id"
    # Only accept the comment when it belongs to issue/PR N.
    fetch gh api "repos/{owner}/{repo}/issues/comments/$id" \
      --jq "$DEFS select(.issue_url | endswith(\"/issues/$n\")) | $JQ_COMMENT"
    parse source "$id" "$incl" <"$tmp"
  else
    fetch gh api "repos/{owner}/{repo}/issues/$n/comments?per_page=100" --paginate --jq "$DEFS .[] | $JQ_COMMENT"
    parse source "" "$incl" <"$tmp"
  fi
}

cmd_search() {
  limit=10; text=""
  while [ $# -gt 0 ]; do
    case "$1" in
      --limit) limit_arg "${2:-}" 100; limit=$2; shift 2 ;;
      *) text="${text:+$text }$1"; shift ;;
    esac
  done
  [ -n "$text" ] || die "usage: search TEXT [--limit N]"
  need_gh; tmp=$(mktemp)
  rest='\(.state | ascii_downcase)\t\(labels)\t\(.title | one)"'
  fetch gh issue list --state all --search "$text" --limit "$limit" \
    --json number,state,labels,title --jq "$DEFS"' .[] | "\(.number)\tissue\t'"$rest"
  fetch gh pr list --state all --search "$text" --limit "$limit" --json number,state,labels,title,isDraft \
    --jq "$DEFS"' .[] | "\(.number)\t\(if .isDraft then "draft-pr" else "pr" end)\t'"$rest"
  printf 'number\ttype\tstate\tlabels\ttitle\n'
  cat "$tmp"
  if [ -z "${GH_REPO:-}" ] && git rev-parse --git-dir >/dev/null 2>&1; then
    git log --all -n "$limit" -i -F --grep="$text" --format='commit%x09%h%x09%s'
  fi
}

[ $# -gt 0 ] || { usage >&2; exit 2; }
if [ "$1" = "-R" ]; then
  [ $# -ge 2 ] || die "-R needs OWNER/REPO"
  GH_REPO=$2; export GH_REPO; shift 2
fi
[ $# -gt 0 ] || { usage >&2; exit 2; }
cmd=$1; shift
case "$cmd" in
  index) cmd_index "$@" ;;
  show) cmd_show "$@" ;;
  source) cmd_source "$@" ;;
  search) cmd_search "$@" ;;
  -h|--help|help) usage ;;
  # Offline entry point for tests: parse a body or record stream from a file.
  # A file without headers is a local record and is trusted.
  parse-file) [ $# -ge 2 ] || die "usage: parse-file index|show|source FILE [SEL] [INCLUDE_UNTRUSTED]"
    [ -f "$2" ] || die "no such file: $2"
    parse "$1" "${3:-}" "${4:-0}" <"$2" ;;
  *) usage >&2; die "unknown command '$cmd'" ;;
esac
