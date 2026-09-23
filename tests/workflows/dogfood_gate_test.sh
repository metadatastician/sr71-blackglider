#!/bin/bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
workflow="$repo_root/.github/workflows/dogfood-gate.yml"

fail() {
    printf 'FAIL: %s\n' "$*" >&2
    exit 1
}

jobs="$(awk '/^jobs:$/ { in_jobs = 1; next } in_jobs && /^  [a-z0-9-]+:$/ { sub(/^  /, ""); sub(/:$/, ""); print }' "$workflow" | sort)"
needs="$(awk '/^  dogfood-summary:$/ { in_summary = 1; next } in_summary && /^  [^ ]/ { exit } in_summary && /^    needs: / { sub(/^[^[]*\[/, ""); sub(/\].*$/, ""); print; exit }' "$workflow")"
[ -n "$jobs" ] && [ -n "$needs" ] || fail 'missing jobs or summary dependencies'
[ "$(printf '%s\n' "$jobs" | grep -cx 'dogfood-summary')" -eq 1 ] || fail 'summary job must appear exactly once'
diff -u <(printf '%s\n' "$jobs" | grep -vx 'dogfood-summary') \
    <(printf '%s\n' "$needs" | tr ',' '\n' | tr -d ' []' | sort) || fail 'summary must depend on every remaining job exactly once'
awk '/^  dogfood-summary:$/ { in_summary = 1; next } in_summary && /^  [^ ]/ { exit } in_summary && /^    if: always\(\)$/ { found = 1 } END { exit !found }' "$workflow" \
    || fail 'summary must run even when a dependency fails'
! grep -Eq 'a2ml-validate:|a2ml-ecosystem/validate-action' "$workflow" || fail 'retired A2ML gate still referenced'

scorecard_script="$(awk '
    /^      - name: Generate dogfooding scorecard$/ { in_step = 1; next }
    in_step && /^        run: \|$/ { in_script = 1; next }
    in_script && /^          / { sub(/^          /, ""); print; next }
    in_script && /^$/ { print; next }
    in_script { exit }
' "$workflow")"
[ -n "$scorecard_script" ] || fail 'scorecard run step not found'

sandbox="$(mktemp -d)"
trap 'rm -rf "$sandbox"' EXIT

run_scorecard() {
    local fixture="$sandbox/$1"
    mkdir -p "$fixture"
    (cd "$fixture" && GITHUB_STEP_SUMMARY="$fixture/summary.md" bash -c "$scorecard_script")
}

assert_row() {
    local summary="$1" label="$2" status="$3"
    grep -Fq "| $label | $status |" "$summary" || fail "wrong $label status in $summary"
}

assert_scorecard() {
    local summary="$1" score="$2" k9="$3" editor="$4" groove="$5" verisimdb="$6" eclexiaiser="$7"
    grep -Fqx "**Score: $score/5**" "$summary" || fail "wrong score in $summary"
    [ "$(grep -Ec '^\| (K9 contracts|\.editorconfig|Groove endpoint|VeriSimDB integration|eclexiaiser) \|' "$summary")" -eq 5 ] \
        || fail "scorecard must contain exactly five tool rows in $summary"
    ! grep -qi 'a2ml' "$summary" || fail "retired A2ML row still present in $summary"
    assert_row "$summary" 'K9 contracts' "$k9"
    assert_row "$summary" '.editorconfig' "$editor"
    assert_row "$summary" 'Groove endpoint' "$groove"
    assert_row "$summary" 'VeriSimDB integration' "$verisimdb"
    assert_row "$summary" 'eclexiaiser' "$eclexiaiser"
}

run_scorecard empty
assert_scorecard "$sandbox/empty/summary.md" 0 ':x:' ':x:' ':ballot_box_with_check:' ':ballot_box_with_check:' ':ballot_box_with_check:'

mkdir -p "$sandbox/legacy"
printf 'legacy manifest\n' > "$sandbox/legacy/0-AI-MANIFEST.a2ml"
run_scorecard legacy
cmp "$sandbox/empty/summary.md" "$sandbox/legacy/summary.md" \
    || fail 'A2ML manifests must not affect the scorecard'

mkdir -p "$sandbox/full/.well-known/groove"
printf 'contract\n' > "$sandbox/full/policy.k9"
printf 'root = true\n' > "$sandbox/full/.editorconfig"
printf '{}\n' > "$sandbox/full/.well-known/groove/manifest.json"
printf 'backend = "verisimdb"\n' > "$sandbox/full/state.toml"
printf 'enabled = true\n' > "$sandbox/full/eclexiaiser.toml"
run_scorecard full
assert_scorecard "$sandbox/full/summary.md" 5 ':white_check_mark:' ':white_check_mark:' ':white_check_mark:' ':white_check_mark:' ':white_check_mark:'

mkdir -p "$sandbox/alternate"
printf 'contract\n' > "$sandbox/alternate/policy.k9.ncl"
printf 'const endpoint = "well-known/groove";\n' > "$sandbox/alternate/endpoint.zig"
run_scorecard alternate
assert_scorecard "$sandbox/alternate/summary.md" 2 ':white_check_mark:' ':x:' ':white_check_mark:' ':ballot_box_with_check:' ':ballot_box_with_check:'

printf 'PASS: dogfood gate dependencies and scorecard fixtures\n'
