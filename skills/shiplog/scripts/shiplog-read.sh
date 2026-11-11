#!/usr/bin/env bash
# shiplog-read.sh - compact, read-only retrieval of shiplog records.
#
# Fetches issue/PR data with `gh`, parses bodies locally with awk and prints
# compact lines, so the model never receives full bodies unless it asks for
# one with `source`. Runtime needs: bash, gh, git, awk, sed, mktemp.
set -eu

usage() {
  cat <<'EOF'
usage: shiplog-read.sh [-R OWNER/REPO] <command> [args]

  index [--limit N]          open issues and PRs, one line each (default N=30)
  show N                     one issue/PR: envelope, computed tasks, open
                             tasks, and enveloped comment entries (no bodies)
  source N [URL|ID]          exact text of one comment, or of every
                             `kind: source` comment on N when none is given
  search TEXT [--limit N]    issues, PRs and local commits matching TEXT

Output columns (tab-separated):
  index:   number type kind tasks labels title summary
  search:  number type state labels title     (then: commit <sha> <subject>)
  type is issue, pr or draft-pr; tasks is done/total or -; empty is -.
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

# Parser. Input is a stream of records; a line starting with \036 is a header:
#   \036R<TAB>number<TAB>type<TAB>state<TAB>labels<TAB>title<TAB>url   (issue/PR)
#   \036C<TAB>url<TAB>created_at                                       (comment)
# followed by the body. Input without a header is read as one record (tests).
# mode: index | show | source.  sel: comment URL or id for source mode.
PARSER=$(cat <<'AWK'
function trim(s) { sub(/^[ \t]+/, "", s); sub(/[ \t]+$/, "", s); return s }
function nz(s) { return (s == "") ? "-" : s }
function reset() {
  infence = 0; fchar = ""; flen = 0; incomment = 0; env = 0; nenv = 0
  kind = ""; summary = ""; first = ""; stored = ""
  gt = 0; gd = 0; gn = 0; st = 0; sd = 0; sn = 0; insec = 0; secseen = 0
  nl = 0; started = 1
}
function header(h,   f) {
  split(h, f, "\t"); rtag = f[1]
  if (rtag == "R") { num = f[2]; typ = f[3]; state = f[4]; labels = f[5]; title = f[6]; url = f[7] }
  else { url = f[2]; date = f[3] }
}
function env_add(s) {
  s = trim(s)
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
  if (first == "" && t != "") first = t
  if (t ~ /^#+[ \t]/) {
    lvl = run_len(t, "#"); h = tolower(trim(substr(t, lvl + 1)))
    if (insec && lvl <= seclvl) insec = 0
    if (!secseen && h ~ /^tasks?([ \t:]|$)/) { insec = 1; secseen = 1; seclvl = lvl }
    return
  }
  if (t ~ /^([-*+]|[0-9]+[.)])[ \t]+\[[ xX]\]([ \t]|$)/) {
    checked = (t ~ /^([-*+]|[0-9]+[.)])[ \t]+\[[xX]\]/)
    item = t; sub(/^([-*+]|[0-9]+[.)])[ \t]+\[[ xX]\][ \t]*/, "", item)
    gt++; if (checked) gd++; else gopen[++gn] = item
    if (insec) { st++; if (checked) sd++; else sopen[++sn] = item }
  }
}
function tasks() {
  if (secseen) { tt = st; td = sd } else { tt = gt; td = gd }
  return (tt == 0) ? "-" : td "/" tt
}
function finish(   i, n, s) {
  if (!started) return
  if (mode == "index" && rtag == "R") {
    print num "\t" typ "\t" nz(kind) "\t" tasks() "\t" nz(labels) "\t" title "\t" nz(summary)
  } else if (mode == "show" && rtag == "R") {
    print "#" num " " typ " " state ": " title
    print "url: " url
    print "labels: " nz(labels)
    s = tasks()
    print "tasks: " s ((s == "-") ? "" : (secseen ? " (computed from the Tasks section)" : " (computed from the whole body)"))
    if (nenv) {
      print "envelope:"
      for (i = 1; i <= nenv; i++) print "  " env_lines[i]
      if (stored) print "  (stored task_count/tasks_complete ignored; see computed tasks above)"
    } else print "envelope: none"
    n = secseen ? sn : gn
    if (n) {
      print "open tasks:"
      for (i = 1; i <= n; i++) print "  - " (secseen ? sopen[i] : gopen[i])
    }
    print "entries:"
  } else if (mode == "show" && rtag == "C") {
    if (kind != "") { print "  " kind " | " date " | " url " | " nz(summary != "" ? summary : first); listed++ }
    else others++
  } else if (mode == "source" && rtag == "C") {
    if ((sel == "" && kind == "source") || (sel != "" && (url == sel || (sel ~ /^[0-9]+$/ && url ~ ("issuecomment-" sel "$"))))) {
      hits++
      print "==> " url " " date
      for (i = 1; i < nl; i++) print lines[i]
      if (nl && lines[nl] != "") print lines[nl]
    }
  }
  started = 0
}
BEGIN { RSC = sprintf("%c", 30) }
{ sub(/\r$/, "") }
substr($0, 1, 1) == RSC { finish(); reset(); header(substr($0, 2)); next }
!started { reset(); header(mode == "source" ? "C\t-\t-" : "R\t-\t-\t-\t-\t-\t-") }
{ line($0) }
END {
  finish()
  if (mode == "show") {
    if (!listed) print "  (none)"
    if (others) print "  plus " others " comment(s) without a shiplog envelope"
  }
  if (mode == "source" && !hits) {
    print "shiplog-read: no matching source entry" (sel == "" ? "" : " for " sel) >"/dev/stderr"
    exit 3
  }
}
AWK
)

parse() { LC_ALL=C awk -v mode="$1" -v sel="${2:-}" "$PARSER"; }

# jq programs (run by gh's built-in --jq) that emit the parser stream.
# L and T are string interpolations for labels and title.
L='\([.labels[].name] | join(","))'
T='\(.title | gsub("\t"; " "))'
JQ_ISSUES='.[] | "\u001eR\t\(.number)\tissue\topen\t'"$L"'\t'"$T"'\t-\n\(.body // "")"'
JQ_PRS='.[] | "\u001eR\t\(.number)\t\(if .isDraft then "draft-pr" else "pr" end)\topen\t'"$L"'\t'"$T"'\t-\n\(.body // "")"'
JQ_RECORD='"\u001eR\t\(.number)\t\(if .pull_request then (if .draft then "draft-pr" else "pr" end) else "issue" end)\t\(.state)\t'"$L"'\t'"$T"'\t\(.html_url)\n\(.body // "")"'
JQ_COMMENT='"\u001eC\t\(.html_url)\t\(.created_at)\n\(.body // "")"'

limit_arg() {
  case "${1:-}" in
    ''|*[!0-9]*) die "--limit needs a positive number" ;;
  esac
  [ "$1" -gt 0 ] || die "--limit needs a positive number"
}

tmp=""
cleanup() { [ -z "$tmp" ] || rm -f "$tmp"; }
trap cleanup EXIT
fetch() { "$@" >>"$tmp" || die "gh $2 $3 failed; check the network, the repository, and gh auth status"; }

cmd_index() {
  limit=30
  while [ $# -gt 0 ]; do
    case "$1" in
      --limit) limit_arg "${2:-}"; limit=$2; shift 2 ;;
      *) die "index: unknown argument '$1'" ;;
    esac
  done
  need_gh; tmp=$(mktemp)
  fetch gh issue list --state open --limit "$limit" --json number,title,labels,body --jq "$JQ_ISSUES"
  fetch gh pr list --state open --limit "$limit" --json number,title,labels,body,isDraft --jq "$JQ_PRS"
  printf 'number\ttype\tkind\ttasks\tlabels\ttitle\tsummary\n'
  parse index <"$tmp"
}

cmd_show() {
  [ $# -eq 1 ] || die "usage: show N"
  need_number "$1"; need_gh; tmp=$(mktemp)
  fetch gh api "repos/{owner}/{repo}/issues/$1" --jq "$JQ_RECORD"
  fetch gh api "repos/{owner}/{repo}/issues/$1/comments?per_page=100" --paginate --jq ".[] | $JQ_COMMENT"
  parse show <"$tmp"
}

cmd_source() {
  [ $# -ge 1 ] && [ $# -le 2 ] || die "usage: source N [comment-URL|ID]"
  need_number "$1"; need_gh; tmp=$(mktemp)
  if [ $# -eq 2 ]; then
    id=$(printf '%s' "$2" | sed -n 's/.*issuecomment-\([0-9][0-9]*\).*/\1/p')
    [ -n "$id" ] || id=$2
    need_number "$id"
    fetch gh api "repos/{owner}/{repo}/issues/comments/$id" --jq "$JQ_COMMENT"
    parse source "$id" <"$tmp"
  else
    fetch gh api "repos/{owner}/{repo}/issues/$1/comments?per_page=100" --paginate --jq ".[] | $JQ_COMMENT"
    parse source <"$tmp"
  fi
}

cmd_search() {
  limit=10; text=""
  while [ $# -gt 0 ]; do
    case "$1" in
      --limit) limit_arg "${2:-}"; limit=$2; shift 2 ;;
      *) text="${text:+$text }$1"; shift ;;
    esac
  done
  [ -n "$text" ] || die "usage: search TEXT [--limit N]"
  need_gh; tmp=$(mktemp)
  rest='\(.state | ascii_downcase)\t\([.labels[].name] | join(",") | if . == "" then "-" else . end)\t'"$T"'"'
  fetch gh issue list --state all --search "$text" --limit "$limit" \
    --json number,state,labels,title --jq '.[] | "\(.number)\tissue\t'"$rest"
  fetch gh pr list --state all --search "$text" --limit "$limit" --json number,state,labels,title,isDraft \
    --jq '.[] | "\(.number)\t\(if .isDraft then "draft-pr" else "pr" end)\t'"$rest"
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
  parse-file) [ $# -ge 2 ] || die "usage: parse-file index|show|source FILE [SEL]"
    [ -f "$2" ] || die "no such file: $2"
    parse "$1" "${3:-}" <"$2" ;;
  *) usage >&2; die "unknown command '$cmd'" ;;
esac
