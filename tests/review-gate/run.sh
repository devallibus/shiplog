#!/usr/bin/env bash
# Offline tests for .github/scripts/review-gate.sh. No network, no jq.
# Each cases/<name>/ holds case.env (EXPECT_EXIT, EXPECT_TEXT, optional CONFIG=missing)
# plus optional comments.json, reviews.json, commits.json, pr-body.md, review.md.
# Missing files fall back to fixtures/ (empty lists, two claude/opus-5.5 commits,
# review: cross-model).
set -uo pipefail

here=$(cd "$(dirname "$0")" && pwd)
gate="$here/../../.github/scripts/review-gate.sh"
HEAD_SHA=a1b2c3d4e5f60718293a4b5c6d7e8f9012345678

if ! command -v node >/dev/null 2>&1; then
  if [ -n "${CI:-}" ]; then echo "FAIL: node is required to run review-gate tests in CI"; exit 1; fi
  echo "SKIP: node not found; review-gate tests not run"
  exit 0
fi

# Relative paths keep Node happy on Windows Git Bash as well as Linux.
cd "$here" || exit 1
passed=0 failed=0
for dir in cases/*/; do
  dir=${dir%/}
  name=${dir#cases/}
  CONFIG="" EXPECT_EXIT="" EXPECT_TEXT=""
  # shellcheck disable=SC1090
  . "$dir/case.env"
  pick() { if [ -f "$dir/$1" ]; then echo "$dir/$1"; else echo "fixtures/$2"; fi; }
  config=$(pick review.md cross-model.md)
  [ "$CONFIG" != missing ] || config="$dir/no-such-file.md"
  body=""
  [ ! -f "$dir/pr-body.md" ] || body="$dir/pr-body.md"
  out=$(bash "$gate" --head "$HEAD_SHA" --config "$config" \
    --comments-file "$(pick comments.json empty.json)" \
    --reviews-file "$(pick reviews.json empty.json)" \
    --commits-file "$(pick commits.json commits.json)" \
    --pr-body-file "$body" 2>/dev/null)
  code=$?
  if [ "$code" = "$EXPECT_EXIT" ] && [[ "$out" == *"$EXPECT_TEXT"* ]]; then
    passed=$((passed + 1)); echo "ok   $name"
  else
    failed=$((failed + 1)); echo "FAIL $name: exit $code (want $EXPECT_EXIT), output: $out (want text: $EXPECT_TEXT)"
  fi
done
echo "review-gate tests: $passed passed, $failed failed"
[ "$failed" -eq 0 ]
