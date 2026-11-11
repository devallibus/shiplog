#!/usr/bin/env bash
# Offline documentation lint for the shiplog skill and plugin commands.
#
# Keeps the "one tree" rule true: every procedure lives under skills/shiplog/,
# links resolve inside that directory, and commands/shiplog/*.md stay thin
# entry points into it. Bash plus POSIX tools only (no jq, no node).
#
# Usage:
#   bash tests/docs/run.sh              lint the repository
#   bash tests/docs/run.sh --self-test  prove the checks fail
#                                       on tests/docs/fixtures/broken and pass on fixtures/clean

set -u

# Budgets. Adjust here if a limit proves wrong for a file.
MAX_SKILL_WORDS=800     # skills/shiplog/SKILL.md
MAX_FILE_WORDS=700      # any other .md under skills/shiplog/
MAX_COMMAND_LINES=20    # each commands/shiplog/*.md

HERE=$(cd "$(dirname "$0")" && pwd)
REPO=$(cd "$HERE/../.." && pwd)
SKILL_DIR=skills/shiplog

FAILURES=0

# Prints "<line>\t<resolved path>\t<raw target>" for every relative markdown
# link in a file. Skips fenced code blocks, inline code, URLs with a scheme,
# and pure #anchors. Resolved paths are normalized and relative to the root.
LINK_AWK='
function norm(p,   n, a, i, k, out, res) {
  n = split(p, a, "/"); k = 0
  for (i = 1; i <= n; i++) {
    if (a[i] == "" || a[i] == ".") continue
    if (a[i] == "..") { if (k > 0 && out[k] != "..") k--; else out[++k] = ".."; continue }
    out[++k] = a[i]
  }
  res = ""
  for (i = 1; i <= k; i++) res = res (i > 1 ? "/" : "") out[i]
  return res
}
{ sub(/\r$/, "") }
/^[ \t]*(```|~~~)/ { infence = !infence; next }
infence { next }
{
  line = $0
  gsub(/`[^`]*`/, "", line)
  while (match(line, /\]\([^)]*\)/)) {
    raw = substr(line, RSTART + 2, RLENGTH - 3)
    line = substr(line, RSTART + RLENGTH)
    t = raw
    sub(/^[ \t]+/, "", t)
    sub(/[ \t].*$/, "", t)
    gsub(/[<>]/, "", t)
    if (t == "" || t ~ /^#/ || t ~ /^[A-Za-z][A-Za-z0-9+.-]*:/) continue
    sub(/[#?].*$/, "", t)
    if (t == "") continue
    print NR "\t" norm(dir "/" t) "\t" raw
  }
}'

links_in() { # <root> <file relative to root>
  awk -v dir="$(dirname "$2")" "$LINK_AWK" "$1/$2"
}

report() { # <status> <name> <detail file>
  if [ "$1" -eq 0 ]; then
    echo "PASS: $2"
  else
    echo "FAIL: $2"
    sed 's/^/  /' "$3"
    FAILURES=$((FAILURES + 1))
  fi
}

TMP=$(mktemp -d 2>/dev/null || mktemp -d -t shiplogdocs)
trap 'rm -rf "$TMP"' EXIT

# --- checks that take a root, so the self-test can point them at fixtures ---

check_links() { # <root>; prints failures, returns 1 on any
  local root=$1 f ln path raw rc=0
  while IFS= read -r f; do
    f=${f#"$root"/}
    while IFS="$(printf '\t')" read -r ln path raw; do
      case $path in
        "$SKILL_DIR"/*)
          [ -f "$root/$path" ] || { echo "$f:$ln: missing link target ($raw)"; rc=1; } ;;
        *)
          echo "$f:$ln: link leaves $SKILL_DIR/ ($raw)"; rc=1 ;;
      esac
    done < <(links_in "$root" "$f")
  done < <(find "$root/$SKILL_DIR" -type f -name '*.md' | sort)
  return $rc
}

check_orphans() { # <root>; files not reachable from SKILL.md
  local root=$1 rc=0 f ln path raw i=0 rel
  declare -A seen=()
  local queue=("$SKILL_DIR/SKILL.md")
  seen["$SKILL_DIR/SKILL.md"]=1
  while [ $i -lt ${#queue[@]} ]; do
    f=${queue[$i]}; i=$((i + 1))
    [ -f "$root/$f" ] || continue
    while IFS="$(printf '\t')" read -r ln path raw; do
      [ -f "$root/$path" ] || continue
      [ -n "${seen[$path]:-}" ] && continue
      seen["$path"]=1
      case $path in *.md) queue+=("$path") ;; esac
    done < <(links_in "$root" "$f")
  done
  # Scripts are invoked from code blocks rather than linked, so a non-markdown
  # file also counts as reachable when a reachable page names its path
  # relative to the skill directory (for example scripts/shiplog-read.sh).
  while IFS= read -r f; do
    f=${f#"$root"/}
    [ -n "${seen[$f]:-}" ] && continue
    rel=${f#"$SKILL_DIR"/}
    case $f in
      *.md) ;;
      *)
        for path in "${!seen[@]}"; do
          case $path in *.md) ;; *) continue ;; esac
          if grep -qF "$rel" "$root/$path"; then seen["$f"]=1; break; fi
        done ;;
    esac
    [ -n "${seen[$f]:-}" ] || { echo "$f: not reachable from $SKILL_DIR/SKILL.md"; rc=1; }
  done < <(find "$root/$SKILL_DIR" -type f | sort)
  return $rc
}

check_root_links() { # <root>; relative links in the front-door files resolve in the repo
  local root=$1 f ln path raw rc=0
  for f in README.md CONTRIBUTING.md CHANGELOG.md; do
    [ -f "$root/$f" ] || continue
    while IFS="$(printf '\t')" read -r ln path raw; do
      case $path in
        ..|../*) echo "$f:$ln: link leaves the repository ($raw)"; rc=1 ;;
        *) [ -e "$root/$path" ] || { echo "$f:$ln: missing link target ($raw)"; rc=1; } ;;
      esac
    done < <(links_in "$root" "$f")
  done
  return $rc
}

check_changelog_version() { # <root>; CHANGELOG.md has a heading for plugin.json's version
  local root=$1 version
  version=$(sed -n 's/^[[:space:]]*"version"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' \
    "$root/.claude-plugin/plugin.json" 2>/dev/null | sed -n 1p)
  [ -n "$version" ] || { echo ".claude-plugin/plugin.json: no version field"; return 1; }
  [ -f "$root/CHANGELOG.md" ] || { echo "CHANGELOG.md: missing"; return 1; }
  # Accept "## 0.6.0", "## [0.6.0]", "## v0.6.0", optionally followed by a date.
  if ! tr -d '\r' < "$root/CHANGELOG.md" | awk -v v="$version" '
      /^##[ \t]/ { h = $2; gsub(/[][]/, "", h); sub(/^v/, "", h); if (h == v) found = 1 }
      END { exit found ? 0 : 1 }'; then
    echo "CHANGELOG.md: no heading for version $version from .claude-plugin/plugin.json"; return 1
  fi
}

check_readme_commands() { # <root>; README names every command, and only real ones
  local root=$1 rc=0 name f
  [ -f "$root/README.md" ] || { echo "README.md: missing"; return 1; }
  for name in $(grep -oE '/shiplog:[a-z0-9][a-z0-9-]*' "$root/README.md" | sed 's|^/shiplog:||' | sort -u); do
    [ -f "$root/commands/shiplog/$name.md" ] ||
      { echo "README.md: /shiplog:$name has no commands/shiplog/$name.md"; rc=1; }
  done
  for f in "$root"/commands/shiplog/*.md; do
    [ -f "$f" ] || continue
    name=$(basename "$f" .md)
    grep -qE "/shiplog:$name([^a-z0-9-]|\$)" "$root/README.md" ||
      { echo "commands/shiplog/$name.md: /shiplog:$name is not mentioned in README.md"; rc=1; }
  done
  return $rc
}

# --- repository-only checks ---

check_commands_path() {
  local rc=0
  if grep -rnF 'commands/' "$REPO/skills" > "$TMP/hits"; then
    sed "s|^$REPO/||" "$TMP/hits"; rc=1
  fi
  return $rc
}

check_command_files() {
  local rc=0 f rel lines refs target
  for f in "$REPO"/commands/shiplog/*.md; do
    [ -f "$f" ] || continue
    rel=${f#"$REPO"/}
    if ! awk '{ sub(/\r$/, "") }
              NR == 1 { if ($0 != "---") exit 1; next }
              $0 == "---" { exit found ? 0 : 1 }
              /^description:[ \t]*[^ \t]/ { found = 1 }
              END { if (NR < 2) exit 1 }' "$f"; then
      echo "$rel:1: frontmatter missing or has no description"; rc=1
    fi
    lines=$(awk 'END { print NR }' "$f")
    if [ "$lines" -gt "$MAX_COMMAND_LINES" ]; then
      echo "$rel: $lines lines (max $MAX_COMMAND_LINES)"; rc=1
    fi
    refs=$(grep -oE '\$\{CLAUDE_PLUGIN_ROOT\}/skills/shiplog/[A-Za-z0-9_./-]+\.md' "$f" | sort -u)
    if [ "$(printf '%s' "$refs" | grep -c .)" -ne 1 ]; then
      echo "$rel: must reference exactly one \${CLAUDE_PLUGIN_ROOT}/skills/shiplog/<file>.md (found: ${refs:-none})" | tr '\n' ' '
      echo; rc=1
      continue
    fi
    target=${refs#'${CLAUDE_PLUGIN_ROOT}/'}
    [ -f "$REPO/$target" ] || { echo "$rel: referenced procedure $target does not exist"; rc=1; }
  done
  return $rc
}

check_word_budget() {
  local rc=0 f rel words limit
  if ! awk '{ sub(/\r$/, "") }
            NR == 1 { if ($0 != "---") exit 1; next }
            $0 == "---" { exit (n && d) ? 0 : 1 }
            /^name:[ \t]*[^ \t]/ { n = 1 }
            /^description:[ \t]*[^ \t]/ { d = 1 }
            END { if (NR < 2) exit 1 }' "$REPO/$SKILL_DIR/SKILL.md"; then
    echo "$SKILL_DIR/SKILL.md:1: frontmatter needs name and description"; rc=1
  fi
  printf '%-8s %-6s %s\n' words limit file > "$TMP/table"
  while IFS= read -r f; do
    rel=${f#"$REPO"/}
    words=$(wc -w < "$f" | tr -d ' ')
    if [ "$rel" = "$SKILL_DIR/SKILL.md" ]; then limit=$MAX_SKILL_WORDS; else limit=$MAX_FILE_WORDS; fi
    printf '%-8s %-6s %s\n' "$words" "$limit" "$rel" >> "$TMP/table"
    if [ "$words" -gt "$limit" ]; then echo "$rel: $words words (max $limit)"; rc=1; fi
  done < <(find "$REPO/$SKILL_DIR" -type f -name '*.md' | sort)
  return $rc
}

# Legacy strings are banned everywhere. A legacy skill reference is
# "shiplog:<lowercase-word>" (pattern from outside contributor PR #165). Not a
# reference: the envelope opener "<!-- shiplog:", "shiplog:" followed by
# whitespace or end of line, labels "shiplog/...", slash commands
# "/shiplog:<name>", and URLs. Hard-coded model names are banned in
# policy prose but allowed inside fenced example blocks, where provenance
# examples such as "Authored-by: <family>/<version>" need a concrete value.
BANNED_AWK='
{ sub(/\r$/, ""); l = tolower($0) }
/^[ \t]*(```|~~~)/ { infence = !infence }
{
  if (index($0, "SKILL.md \302\247")) print FILENAME ":" FNR ": legacy citation \"SKILL.md \302\247\""
  ref = $0
  gsub(/[A-Za-z][A-Za-z0-9+.-]*:\/\/[^ \t<>()`"]*/, "", ref)
  gsub(/<!--[ \t]*shiplog:/, "", ref)
  while (match(ref, /(^|[^\/])shiplog:[a-z][a-z0-9_-]*/)) {
    hit = substr(ref, RSTART, RLENGTH); hit = substr(hit, index(hit, "shiplog:"))
    print FILENAME ":" FNR ": legacy skill reference \"" hit "\""
    ref = substr(ref, RSTART + RLENGTH)
  }
  if (index(l, "phase entry check")) print FILENAME ":" FNR ": legacy \"Phase Entry Check\""
  if (!infence) {
    if (index(l, "opus-4")) print FILENAME ":" FNR ": model name \"opus-4\" outside a fenced example"
    if (index(l, "sonnet-4")) print FILENAME ":" FNR ": model name \"sonnet-4\" outside a fenced example"
    if (index(l, "gpt-5")) print FILENAME ":" FNR ": model name \"gpt-5\" outside a fenced example"
    if (index(l, "gpt-4.1")) print FILENAME ":" FNR ": model name \"GPT-4.1\" outside a fenced example"
    if (l ~ /(^|[^a-z0-9])o3([^a-z0-9]|$)/) print FILENAME ":" FNR ": model name \"o3\" outside a fenced example"
  }
}'

check_banned() { # <root>
  local root=$1 files
  files=$(find "$root/skills" "$root/commands" -type f -name '*.md' 2>/dev/null | sort)
  [ -n "$files" ] || return 0
  # shellcheck disable=SC2086
  awk "$BANNED_AWK" $files > "$TMP/banned.raw" || { echo "check_banned: awk failed"; return 1; }
  sed "s|^$root/||" "$TMP/banned.raw" > "$TMP/banned"
  cat "$TMP/banned"
  [ ! -s "$TMP/banned" ]
}

check_shell_syntax() {
  local rc=0 d f
  for d in "$REPO/$SKILL_DIR/scripts" "$REPO/.github/scripts"; do
    [ -d "$d" ] || continue
    while IFS= read -r f; do
      case $f in
        *.sh) ;;
        *) head -n 1 "$f" | grep -qE '^#!.*\b(ba)?sh\b' || continue ;;
      esac
      if ! bash -n "$f" 2> "$TMP/syntax"; then
        echo "${f#"$REPO"/}: bash -n failed"; sed 's/^/  /' "$TMP/syntax"; rc=1
      fi
    done < <(find "$d" -type f | sort)
  done
  return $rc
}

run_check() { # <name> <function> [args]
  local name=$1; shift
  "$@" > "$TMP/out" 2>&1
  report $? "$name" "$TMP/out"
}

# --- self-test ---

expect() { # <description> <condition result 0|1>
  if [ "$2" -eq 0 ]; then echo "PASS: self-test: $1"; else echo "FAIL: self-test: $1"; FAILURES=$((FAILURES + 1)); fi
}

self_test() {
  local broken="$HERE/fixtures/broken" clean="$HERE/fixtures/clean" out
  out=$(check_links "$broken"); rc=$?
  echo "--- check_links on fixtures/broken:"; printf '%s\n' "$out" | sed 's/^/  /'
  expect "link check fails on broken tree" $([ $rc -ne 0 ]; echo $?)
  expect "reports missing target" $(printf '%s' "$out" | grep -q 'missing.md'; echo $?)
  expect "reports link leaving the skill directory" $(printf '%s' "$out" | grep -q 'leaves.*outside.md'; echo $?)
  expect "ignores links in fenced code" $(! printf '%s' "$out" | grep -q 'fenced-missing.md'; echo $?)
  expect "ignores links in inline code" $(! printf '%s' "$out" | grep -q 'code-missing.md'; echo $?)
  expect "ignores URLs and anchors" $(! printf '%s' "$out" | grep -qE 'example.com|#top'; echo $?)

  out=$(check_orphans "$broken"); rc=$?
  echo "--- check_orphans on fixtures/broken:"; printf '%s\n' "$out" | sed 's/^/  /'
  expect "orphan check fails on broken tree" $([ $rc -ne 0 ]; echo $?)
  expect "reports unlinked page" $(printf '%s' "$out" | grep -q 'shiplog/orphan.md'; echo $?)
  expect "reports unmentioned script" $(printf '%s' "$out" | grep -q 'scripts/orphan.sh'; echo $?)
  expect "a fenced link does not make a page reachable" $(printf '%s' "$out" | grep -q 'fenced-only.md'; echo $?)
  expect "linked page is reachable" $(! printf '%s' "$out" | grep -q 'good.md'; echo $?)
  expect "script named by a reachable page is reachable" $(! printf '%s' "$out" | grep -q 'scripts/used.sh'; echo $?)

  out=$(check_banned "$broken"); rc=$?
  echo "--- check_banned on fixtures/broken:"; printf '%s\n' "$out" | sed 's/^/  /'
  expect "banned check fails on broken tree" $([ $rc -ne 0 ]; echo $?)
  expect "reports legacy section citation" $(printf '%s' "$out" | grep -q 'legacy citation'; echo $?)
  expect "reports model name in prose" $(printf '%s' "$out" | grep -q 'gpt-5'; echo $?)
  expect "allows model name in fenced example" $(! printf '%s' "$out" | grep -q 'opus-4'; echo $?)
  expect "reports legacy skill reference" $(printf '%s' "$out" | grep -q 'legacy skill reference "shiplog:timeline"'; echo $?)
  expect "reports exactly one legacy skill reference" $([ "$(printf '%s
' "$out" | grep -c 'legacy skill reference')" -eq 1 ]; echo $?)
  expect "allows envelope opener" $(! printf '%s' "$out" | grep -q 'shiplog:envword'; echo $?)
  expect "allows slash command" $(! printf '%s' "$out" | grep -q 'shiplog:hunt'; echo $?)
  expect "allows URL" $(! printf '%s' "$out" | grep -q 'shiplog:urlword'; echo $?)

  out=$(check_root_links "$broken"); rc=$?
  echo "--- check_root_links on fixtures/broken:"; printf '%s\n' "$out" | sed 's/^/  /'
  expect "root link check fails on broken tree" $([ $rc -ne 0 ]; echo $?)
  expect "reports missing README target" $(printf '%s' "$out" | grep -q 'README.md:.*missing-doc.md'; echo $?)
  expect "reports link leaving the repository" $(printf '%s' "$out" | grep -q 'leaves the repository'; echo $?)
  expect "accepts an existing directory and file" $(! printf '%s' "$out" | grep -qE 'outside.md|\(skills/'; echo $?)

  out=$(check_changelog_version "$broken"); rc=$?
  echo "--- check_changelog_version on fixtures/broken:"; printf '%s\n' "$out" | sed 's/^/  /'
  expect "changelog check fails when the version has no heading" $([ $rc -ne 0 ]; echo $?)
  expect "reports the missing version" $(printf '%s' "$out" | grep -q '9.9.9'; echo $?)

  out=$(check_readme_commands "$broken"); rc=$?
  echo "--- check_readme_commands on fixtures/broken:"; printf '%s\n' "$out" | sed 's/^/  /'
  expect "command mention check fails on broken tree" $([ $rc -ne 0 ]; echo $?)
  expect "reports README command without a file" $(printf '%s' "$out" | grep -q '/shiplog:ghost has no'; echo $?)
  expect "reports command file missing from README" $(printf '%s' "$out" | grep -q 'unlisted.md'; echo $?)
  expect "a longer name does not count as a mention" $(printf '%s' "$out" | grep -q 'go.md'; echo $?)
  expect "mentioned command with a file passes" $(! printf '%s' "$out" | grep -qE '/shiplog/listed[.]md:|/shiplog:listed '; echo $?)

  check_links "$clean" > /dev/null; expect "link check passes on clean tree" $?
  check_orphans "$clean" > /dev/null; expect "orphan check passes on clean tree" $?
  check_root_links "$clean" > /dev/null; expect "root link check passes on clean tree" $?
  check_changelog_version "$clean" > /dev/null; expect "changelog check passes on clean tree" $?
  check_readme_commands "$clean" > /dev/null; expect "command mention check passes on clean tree" $?
  check_banned "$clean" > /dev/null; expect "banned check passes on clean tree (legacy-reference exceptions)" $?
}

if [ "${1:-}" = "--self-test" ]; then
  self_test
else
  run_check "relative links resolve inside $SKILL_DIR/" check_links "$REPO"
  run_check "skills/ never points at commands/" check_commands_path
  run_check "commands are thin entry points into the skill" check_command_files
  run_check "SKILL.md frontmatter and word budgets" check_word_budget
  sed 's/^/  /' "$TMP/table"
  run_check "no banned legacy strings or hard-coded model names" check_banned "$REPO"
  run_check "every file under $SKILL_DIR/ is reachable from SKILL.md" check_orphans "$REPO"
  run_check "shell scripts pass bash -n" check_shell_syntax
  run_check "relative links in README, CONTRIBUTING and CHANGELOG resolve" check_root_links "$REPO"
  run_check "CHANGELOG.md has a heading for the plugin.json version" check_changelog_version "$REPO"
  run_check "README and commands/shiplog/ name the same commands" check_readme_commands "$REPO"
fi

LABEL="docs lint"
[ "${1:-}" = "--self-test" ] && LABEL="docs lint self-test"
echo
if [ "$FAILURES" -eq 0 ]; then echo "$LABEL: all checks passed"; exit 0; fi
echo "$LABEL: $FAILURES check(s) failed"
exit 1
