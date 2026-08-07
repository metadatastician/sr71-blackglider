#!/usr/bin/env bash
# SPDX-License-Identifier: MPL-2.0
# Copyright (c) 2026 Jonathan D.A. Jewell (hyperpolymath) <j.d.a.jewell@open.ac.uk>
#
# RSR Standard Aspect Test Template
#
# Aspect tests validate cross-cutting architectural invariants that span
# the entire codebase. These are NOT functional tests — they verify that
# coding standards, safety rules, and structural contracts hold.
#
# Usage:
#   bash tests/aspect_tests.sh
#   just aspect
#
# Standard aspects (enable what applies to your project):
#   1. SPDX compliance — all source files have license headers
#   2. Dangerous patterns — no believe_me, assert_total, sorry, unsafeCoerce, etc.
#   3. ABI/FFI contract — declarations match exports
#   4. Thread safety — mutex in FFI modules
#   5. Error handling — no panic/unreachable in production paths

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$PROJECT_DIR"

PASS=0
FAIL=0
WARN=0

green() { printf '\033[32m%s\033[0m\n' "$*"; }
red()   { printf '\033[31m%s\033[0m\n' "$*"; }
yellow(){ printf '\033[33m%s\033[0m\n' "$*"; }
bold()  { printf '\033[1m%s\033[0m\n' "$*"; }

pass() { green "  PASS: $1"; PASS=$((PASS + 1)); }
fail() { red "  FAIL: $1"; FAIL=$((FAIL + 1)); }
warn() { yellow "  WARN: $1"; WARN=$((WARN + 1)); }

echo "═══════════════════════════════════════════════════════════════"
echo "  SR71_BLACKGLIDER — Aspect Tests (Cross-Cutting Concerns)"
echo "═══════════════════════════════════════════════════════════════"
echo ""

# ═══════════════════════════════════════════════════════════════════════
# Aspect 1: SPDX License Headers
# ═══════════════════════════════════════════════════════════════════════
bold "Aspect 1: SPDX license headers"

# Enumerate via `git ls-files`, not a bare `find`.
#
# A bare `find src/` descends into build output. The moment the Zig FFI seam
# gained a working build.zig (2026-08-04) this check went red on
# src/interface/ffi/.zig-cache/**/dependencies.zig — a generated file that is
# gitignored and can never carry an SPDX header. Enabling a real build must
# not break an unrelated gate; the gate was asking the wrong question.
#
# `git ls-files` answers "what does this repository actually contain",
# which is what a licence-header check means. The find fallback keeps the
# script working outside a git work tree.
MISSING_SPDX=0
SPDX_SCAN_EXTS='rs|zig|res|ex|exs|gleam|idr|sh'
if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    SPDX_FILES=$(git ls-files -- 'src/*' | grep -E "\.($SPDX_SCAN_EXTS)$" || true)
else
    SPDX_FILES=$(find src/ -type f 2>/dev/null \
        ! -path '*/.zig-cache/*' ! -path '*/zig-cache/*' ! -path '*/build/*' \
        | grep -E "\.($SPDX_SCAN_EXTS)$" || true)
fi
while IFS= read -r f; do
    [ -z "$f" ] && continue
    if ! head -5 "$f" | grep -q "SPDX-License-Identifier"; then
        warn "Missing SPDX header: $f"
        MISSING_SPDX=$((MISSING_SPDX + 1))
    fi
done <<< "$SPDX_FILES"

if [ "$MISSING_SPDX" -eq 0 ]; then
    pass "All source files have SPDX headers"
else
    fail "$MISSING_SPDX files missing SPDX headers"
fi

# ═══════════════════════════════════════════════════════════════════════
# Aspect 2: Dangerous Patterns (BANNED)
# ═══════════════════════════════════════════════════════════════════════
bold "Aspect 2: Dangerous patterns"

# Delegates to scripts/scan-dangerous.sh — the single implementation of
# "which constructs escape a proof obligation, and where".
#
# This aspect used to carry its own second copy of that rule, and the copy had
# rotted in three independent ways:
#
#   1. The Idris2 arm grepped `src/abi/` — a path that has NEVER existed here
#      (the sources are `src/interface/Abi/`, capital A, and
#      `verification/proofs/idris2/`). grep on a missing directory matches
#      nothing, so the check reported PASS unconditionally from the day it was
#      written: a gate that could not fail, inside the file whose entire job is
#      catching gates that cannot fail. Verified 2026-08-04:
#      `ls -d src/abi/` -> No such file or directory.
#   2. Both arms matched prose. The bare word `believe_me` hit the modules'
#      own "no believe_me" header comments, and `Admitted` hit TypeSafety.v's
#      "NO Admitted allowed" line — a rule tripping on its own prohibition.
#   3. The final `| grep -v "test"` discarded every finding whose PATH contains
#      "test", so a `sorry` anywhere under tests/ was silently invisible.
#
# scan-dangerous.sh already solves all three properly: it blanks comment
# bodies in place (line + block comments, per language) before matching, and
# covers seven constructs across Idris2/Lean4/Agda/Coq rather than this copy's
# three. Two implementations of one rule is how the weaker one ends up being
# the one that runs — so there is now one, and this calls it.
if bash "$PROJECT_DIR/scripts/scan-dangerous.sh"; then
    pass "No dangerous constructs used in proof code (scan-dangerous.sh)"
else
    fail "Dangerous constructs found in proof code — see scan-dangerous.sh output above"
fi

# ═══════════════════════════════════════════════════════════════════════
# Aspect 3: ABI/FFI Contract (if applicable)
# ═══════════════════════════════════════════════════════════════════════
# Uncomment if your project has Idris2 ABI + Zig FFI:

# bold "Aspect 3: ABI/FFI contract"
# if [ -d "src/abi" ] && [ -d "ffi/zig" ]; then
#     # Check that every exported function in Idris2 ABI has a Zig FFI implementation
#     ABI_EXPORTS=$(grep -h 'export' src/abi/*.idr 2>/dev/null | wc -l)
#     FFI_EXPORTS=$(grep -h 'pub export fn' ffi/zig/src/*.zig 2>/dev/null | wc -l)
#     if [ "$ABI_EXPORTS" -gt 0 ] && [ "$FFI_EXPORTS" -gt 0 ]; then
#         pass "ABI ($ABI_EXPORTS exports) and FFI ($FFI_EXPORTS exports) both present"
#     else
#         fail "ABI/FFI mismatch: $ABI_EXPORTS ABI exports, $FFI_EXPORTS FFI exports"
#     fi
# else
#     pass "ABI/FFI not applicable (no src/abi or ffi/zig)"
# fi

# ═══════════════════════════════════════════════════════════════════════
# Aspect 4: Error Handling (no raw panic in production code)
# ═══════════════════════════════════════════════════════════════════════
# Uncomment for Rust projects:

# bold "Aspect 4: Error handling"
# UNWRAP_COUNT=$(grep -rn '\.unwrap()' src/ 2>/dev/null | grep -v "test" | grep -v "example" | wc -l)
# if [ "$UNWRAP_COUNT" -gt 20 ]; then
#     warn "$UNWRAP_COUNT .unwrap() calls in src/ — consider replacing with ? or expect()"
# else
#     pass "Acceptable unwrap count: $UNWRAP_COUNT"
# fi

# ═══════════════════════════════════════════════════════════════════════
# Summary
# ═══════════════════════════════════════════════════════════════════════
echo ""
echo "═══════════════════════════════════════════════════════════════"
printf "  Results: "
green "PASS=$PASS" | tr -d '\n'
echo -n "  "
if [ "$FAIL" -gt 0 ]; then red "FAIL=$FAIL" | tr -d '\n'; else echo -n "FAIL=0"; fi
echo -n "  "
if [ "$WARN" -gt 0 ]; then yellow "WARN=$WARN"; else echo "WARN=0"; fi
echo ""
echo "═══════════════════════════════════════════════════════════════"

exit "$FAIL"
