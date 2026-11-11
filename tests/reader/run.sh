#!/usr/bin/env bash
# Offline tests for skills/shiplog/scripts/shiplog-read.sh (no network, no jq).
# Usage: bash tests/reader/run.sh
set -eu

here=$(cd "$(dirname "$0")" && pwd)
reader="$here/../../skills/shiplog/scripts/shiplog-read.sh"
fx="$here/fixtures"
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT

pass=0; fail=0
check() { # name expected actual
  if [ "$2" = "$3" ]; then
    pass=$((pass + 1)); printf 'PASS %s\n' "$1"
  else
    fail=$((fail + 1)); printf 'FAIL %s\n  expected: %s\n  actual:   %s\n' "$1" "$2" "$3"
  fi
}
# Fixtures may be checked out with CRLF; tests compare against LF text.
lf() { tr -d '\r' <"$1" >"$work/$(basename "$1")"; printf '%s' "$work/$(basename "$1")"; }
run() { bash "$reader" parse-file "$@"; }
tab=$(printf '\t')
row() { printf '%s' "$*" | tr '|' "$tab"; } # expected index row, | for tab

f=$(lf "$fx/long-envelope.md")
check "envelope longer than 15 lines: index row" \
  "$(row '-|-|state|1/2|-|-|Envelope with more than fifteen lines.')" "$(run index "$f")"
check "envelope longer than 15 lines: last field kept" \
  "  last_field: still-read" "$(run show "$f" | grep 'last_field')"
check "envelope longer than 15 lines: all 18 fields" \
  "18" "$(run show "$f" | sed -n '/^envelope:/,/^open tasks:/p' | grep -c ': ')"

awk '{ printf "%s\r\n", $0 }' "$f" >"$work/crlf.md"
check "CRLF input: same index row as LF" "$(run index "$f")" "$(run index "$work/crlf.md")"
check "CRLF input: no carriage return in output" "0" \
  "$(run show "$work/crlf.md" | tr -cd '\r' | wc -c | tr -d ' ')"

f=$(lf "$fx/no-envelope.md")
check "no envelope: index row" "$(row '-|-|-|1/3|-|-|-')" "$(run index "$f")"
check "no envelope: show says none" "envelope: none" "$(run show "$f" | grep '^envelope')"

f=$(lf "$fx/old-envelope.md")
check "old envelope: computed count beats stale task_count" \
  "$(row '-|-|state|2/3|-|-|-')" "$(run index "$f")"
check "old envelope: extra fields passed through" \
  "  readiness: ready" "$(run show "$f" | grep 'readiness')"
check "old envelope: open task from Tasks section only" \
  "  - **T3: still open** \`[tier-1]\`" "$(run show "$f" | sed -n '/^open tasks:/{n;p;}')"

f=$(lf "$fx/nested.md")
check "nested and indented checkboxes: counts" \
  "$(row '-|-|state|3/6|-|-|Nested and mixed checkbox styles.')" "$(run index "$f")"
check "nested and indented checkboxes: open titles" \
  "T1: parent|T1.2: deeper child|T3: ordered item" \
  "$(run show "$f" | sed -n 's/^  - //p' | tr '\n' '|' | sed 's/|$//')"

f=$(lf "$fx/source-fence.md")
check "source with inner fences: kind and no fake tasks" \
  "$(row '-|-|source|-|-|-|User message that itself contains a code fence.')" "$(run index "$f")"
run source "$f" | tail -n +2 >"$work/source.out"
if cmp -s "$f" "$work/source.out"; then check "source with inner fences: verbatim text" same same
else check "source with inner fences: verbatim text" "byte-identical" "differs"; fi

f=$(lf "$fx/html-comment.md")
check "non-shiplog HTML comment ignored" \
  "$(row '-|-|decision|0/1|-|-|The real envelope comes after other comments.')" "$(run index "$f")"

# A record stream as the gh --jq programs emit it: \036 header lines + bodies.
rs=$(printf '\036')
{
  printf '%sR\t7\tissue\topen\tshiplog/ready\tStream title\thttps://x/issues/7\n' "$rs"
  cat "$(lf "$fx/old-envelope.md")"
  printf '%sC\thttps://x/issues/7#issuecomment-11\t2026-01-02T00:00:00Z\n' "$rs"
  cat "$(lf "$fx/source-fence.md")"
  printf '%sC\thttps://x/issues/7#issuecomment-12\t2026-01-03T00:00:00Z\nplain comment\n' "$rs"
  printf '%sC\thttps://x/issues/7#issuecomment-13\t2026-01-04T00:00:00Z\n' "$rs"
  cat "$(lf "$fx/html-comment.md")"
} >"$work/stream"
check "stream: show lists enveloped comments only" \
  "  source | 2026-01-02T00:00:00Z | https://x/issues/7#issuecomment-11 | User message that itself contains a code fence.|  decision | 2026-01-04T00:00:00Z | https://x/issues/7#issuecomment-13 | The real envelope comes after other comments.|  plus 1 comment(s) without a shiplog envelope" \
  "$(run show "$work/stream" | sed -n '/^entries:/,$p' | sed 1d | tr '\n' '|' | sed 's/|$//')"
check "stream: source selects by comment id" \
  "==> https://x/issues/7#issuecomment-12 2026-01-03T00:00:00Z|plain comment" \
  "$(run source "$work/stream" 12 | tr '\n' '|' | sed 's/|$//')"
check "stream: source without id returns kind source only" "1" \
  "$(run source "$work/stream" | grep -c '^==> ')"
if run source "$work/stream" 99 >/dev/null 2>&1; then
  check "stream: unknown id fails" "non-zero exit" "exit 0"
else check "stream: unknown id fails" ok ok; fi

printf '%s passed, %s failed\n' "$pass" "$fail"
[ "$fail" -eq 0 ]
