#!/usr/bin/env bash
# SPDX-License-Identifier: MPL-2.0
# Copyright (c) 2026 Jonathan D.A. Jewell (metadatastician) <j.d.a.jewell@open.ac.uk>
#
# SR-71 BlackGlider — End-to-end pipeline test
#
# End-to-end here means the real pipeline this repository ships: build the
# kernel in RELEASE mode and run the exhaustive C1–C13 gates against the
# optimized artifact. rust-ci already runs the suite in debug; this harness
# proves the same constitutional claims hold under optimization (a different
# codegen path over the same 512-rule / 65,536-world / Snark-trace domains),
# which is the closest thing to "build → run → verify output" a library
# foundation has. The proof gate runs when idris2 is available and SKIPs
# loudly when it is not (CI runners don't carry idris2; `just test` does).
#
# The template-instantiation smoke that previously lived here belonged to
# rsr-template-repo, not to a minted project — per this file's own original
# instruction ("delete the examples that don't apply"), it was removed
# 2026-08-03 when the harness was instantiated for real.
#
# Usage:
#   bash tests/e2e.sh
#   just e2e

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

PASS=0
FAIL=0
SKIP=0

# ─── Colour helpers ──────────────────────────────────────────────────
green() { printf '\033[32m%s\033[0m\n' "$*"; }
red()   { printf '\033[31m%s\033[0m\n' "$*"; }
yellow(){ printf '\033[33m%s\033[0m\n' "$*"; }
bold()  { printf '\033[1m%s\033[0m\n' "$*"; }

# run_gate <label> <command...> — run a command, count PASS/FAIL loudly
run_gate() {
    local name="$1"; shift
    if "$@"; then
        green "  PASS: $name"
        PASS=$((PASS + 1))
    else
        red "  FAIL: $name"
        FAIL=$((FAIL + 1))
    fi
}

skip_test() {
    yellow "  SKIP: $1 ($2)"
    SKIP=$((SKIP + 1))
}

echo "═══════════════════════════════════════════════════════════════"
echo "  SR-71 BlackGlider — End-to-End Pipeline"
echo "═══════════════════════════════════════════════════════════════"
echo ""

# ─── Preflight ───────────────────────────────────────────────────────
bold "Preflight checks"
command -v cargo >/dev/null 2>&1 || { red "  cargo not found — install a Rust toolchain"; exit 1; }
green "  cargo found: $(cargo --version)"
echo ""

# ─── Section 1: release build ────────────────────────────────────────
bold "Section 1: release build"
run_gate "cargo build --release --all-targets" \
    cargo build --release --all-targets --manifest-path "$PROJECT_DIR/Cargo.toml"
echo ""

# ─── Section 2: exhaustive gates under optimization ──────────────────
bold "Section 2: C1–C13 exhaustive gates (release mode)"
run_gate "cargo test --release --all-targets" \
    cargo test --release --all-targets --manifest-path "$PROJECT_DIR/Cargo.toml"
echo ""

# ─── Section 3: constitutional proof gate (when a prover is present) ─
bold "Section 3: Idris2 constitutional gate"
if command -v idris2 >/dev/null 2>&1; then
    run_gate "check-proofs.sh idris2 (MANIFEST-gated)" \
        bash "$PROJECT_DIR/scripts/check-proofs.sh" idris2
else
    skip_test "check-proofs.sh idris2" "idris2 not installed on this runner; covered by 'just test' locally"
fi

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
if [ "$SKIP" -gt 0 ]; then yellow "SKIP=$SKIP"; else echo "SKIP=0"; fi
echo "═══════════════════════════════════════════════════════════════"

exit "$FAIL"
