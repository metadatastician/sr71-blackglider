# SPDX-License-Identifier: MPL-2.0
# Copyright (c) 2026 Jonathan D.A. Jewell (hyperpolymath) <j.d.a.jewell@open.ac.uk>
#
# RSR Standard Justfile Template
# https://just.systems/man/en/
#
# Copy this file to new projects and customize the placeholder values.
#
# Run `just` to see all available recipes
# Run `just cookbook` to generate docs/just-cookbook.adoc
# Run `just combinations` to see matrix recipe options

set shell := ["bash", "-uc"]
set dotenv-load := true
set positional-arguments := true

# Import auto-generated contractile recipes (must-check, trust-verify, etc.)
# Re-generate with: contractile gen-just
import? "build/contractile.just"

# Project metadata — customize these
project := "sr71-blackglider"
OWNER := "metadatastician"
REPO := "sr71-blackglider"
version := "0.1.0"
tier := "2"  # 1 | 2 | infrastructure

# ═══════════════════════════════════════════════════════════════════════════════
# DEFAULT & HELP
# ═══════════════════════════════════════════════════════════════════════════════

# Show all available recipes with descriptions
default:
    @just --list --unsorted

# Show detailed help for a specific recipe
help recipe="":
    #!/usr/bin/env bash
    if [ -z "{{recipe}}" ]; then
        just --list --unsorted
        echo ""
        echo "Usage: just help <recipe>"
        echo "       just cookbook     # Generate full documentation"
        echo "       just combinations # Show matrix recipes"
    else
        just --show "{{recipe}}" 2>/dev/null || echo "Recipe '{{recipe}}' not found"
    fi

# Show this project's info
info:
    @echo "Project: sr71_blackglider"
    @echo "Version: {{version}}"
    @echo "RSR Tier: {{tier}}"
    @echo "Recipes: $(just --summary | wc -w)"
    @[ -f ".machine_readable/descriptiles/STATE.a2ml" ] && grep -oP 'phase\s*=\s*"\K[^"]+' .machine_readable/descriptiles/STATE.a2ml | head -1 | xargs -I{} echo "Phase: {}" || true

# Run Invariant Path overlay tools for this repository
invariant-path *ARGS:
    ./scripts/invariant-path.sh {{ARGS}}

# ═══════════════════════════════════════════════════════════════════════════════
# INIT — see build/just/init.just
# ═══════════════════════════════════════════════════════════════════════════════

import? "build/just/init.just"

# >>> container-module (three-tier: OCI · portable engine · stapeln) >>>
# Self-contained. Remove the entire block — this and the import — with `just no-container`.
import? "build/just/container.just"
# <<< container-module <<<

# ═══════════════════════════════════════════════════════════════════════════════
# GROOVE PROTOCOL — see build/just/groove.just
# ═══════════════════════════════════════════════════════════════════════════════

import? "build/just/groove.just"

# ═══════════════════════════════════════════════════════════════════════════════
# PROJECT SELF-ASSESSMENT + OPENSSF COMPLIANCE — see build/just/assess.just
# ═══════════════════════════════════════════════════════════════════════════════

import? "build/just/assess.just"

# ═══════════════════════════════════════════════════════════════════════════════
# BUILD & COMPILE
# ═══════════════════════════════════════════════════════════════════════════════

# Build the project (debug mode)
build *args:
    cargo build --all-targets {{args}}

# Build in release mode with optimizations
build-release *args:
    cargo build --release --all-targets {{args}}

# Build and watch for changes (requires entr or similar)
build-watch:
    @echo "Watching for changes..."
    # TODO: Customize file patterns for your language
    # Examples:
    #   find src -name '*.rs' | entr -c just build
    #   mix compile --force --warnings-as-errors
    #   deno task dev

# Clean build artifacts [reversible: rebuild with `just build`]
clean:
    @echo "Cleaning..."
    # TODO: Customize for your build system
    #
    # `build/` is DELIBERATELY ABSENT from this list. It is not an artifact
    # directory in an RSR repo: it holds 11 tracked files, including
    # build/just/init.just, which the root Justfile imports at line 65.
    # Deleting it destroys `just init`, `just verify` and the proof gates.
    rm -rf target/ _build/ dist/ out/ obj/ bin/

# Deep clean including caches [reversible: rebuild]
clean-all: clean
    rm -rf .cache .tmp

# ═══════════════════════════════════════════════════════════════════════════════
# TEST & QUALITY
# ═══════════════════════════════════════════════════════════════════════════════

# Run all tests. Every prover with proofs in-tree is gated here — the gate
# script FAILS (never skips) when a toolchain is absent, so a green
# `just test` means every proof was actually checked on this machine.
test *args:
    cargo test --all-targets {{args}}
    cd src/interface/ffi && zig build test --summary all
    # The SHIPPED ABI seam (src/interface/Abi/, three modules) — distinct from
    # the template proofs under verification/proofs/idris2/, which is all
    # check-proofs.sh's MANIFEST covers. Nothing gated this until 2026-08-07,
    # so the one Idris2 artefact the FFI actually depends on was the one
    # artefact no gate checked. A package typecheck is the honest form here;
    # per-file --check warns on module/path mismatch by design (see abi.ipkg).
    idris2 --typecheck abi.ipkg
    bash scripts/check-proofs.sh idris2
    bash scripts/check-proofs.sh coq
    bash scripts/check-proofs.sh agda
    bash scripts/check-proofs.sh lean4

# Run tests with verbose output
test-verbose:
    cargo test --all-targets -- --nocapture

# Smoke test
test-smoke:
    cargo test --test foundation c1_all_512_local_configurations_are_exactly_b3_s23

# Run end-to-end tests (full pipeline: build → run → verify)
#
# Ran a single hand-picked cargo test (c3_c4_snark_reaction) rather than
# tests/e2e.sh, so "e2e passed" meant one assertion out of the release-mode
# pipeline the harness actually defines.
e2e:
    bash tests/e2e.sh

# Run aspect tests (cross-cutting concern validation)
#
# Was an echo-only TODO stub that printed "Aspect tests passed!" and exited 0
# while running nothing — and `test-all` depended on it, so the merge-gate
# recipe announced "safe to merge" on the strength of an echo. The harness it
# was meant to call has existed all along.
aspect:
    bash tests/aspect_tests.sh


# Run benchmarks — NOT IMPLEMENTED, and says so.
#
# Exits non-zero rather than printing "Benchmarks complete!" over an empty
# body. It was an echo-only stub that `test-all` depended on, so the
# merge-gate recipe counted a benchmark suite that never ran. The repo
# declares no `benchmarks` capability (.machine_readable/rsr-profile.a2ml)
# and ships no cargo bench target; benches/template_bench.sh times template
# mechanics, not this kernel. Tracked as DEBT T-3.
bench:
    #!/usr/bin/env bash
    echo "NOT IMPLEMENTED: no benchmark suite exists for this project." >&2
    echo "  The kernel has no cargo bench target; benches/template_bench.sh" >&2
    echo "  benchmarks RSR template mechanics, not Conway evolution." >&2
    echo "  See DEBT.md (T-3). This recipe fails rather than claim success." >&2
    exit 1

# Run readiness tests — NOT IMPLEMENTED, and says so.
#
# Same defect and same reasoning as `bench`. The Component Readiness Grade is
# assessed by hand in docs/status/READINESS.adoc against the CRG v2.0 evidence
# gates; there is no executable readiness suite. Tracked as DEBT T-3.
readiness:
    #!/usr/bin/env bash
    echo "NOT IMPLEMENTED: there is no executable readiness suite." >&2
    echo "  CRG is assessed in docs/status/READINESS.adoc; run 'just crg-grade'" >&2
    echo "  to read the recorded grade. See DEBT.md (T-3)." >&2
    exit 1

# Print the current CRG grade, read from docs/status/READINESS.adoc.
#
# Had three independent faults: Makefile `$$` escaping leaked into a Justfile
# (bash read `$$` as the PID, then choked on the following paren — a hard
# syntax error, exit 2); it read `READINESS.md`, which does not exist here;
# and it matched `**Current Grade:** X` (Markdown bold) where the AsciiDoc
# file writes `*Current Grade:* X`. Three ways to be wrong about one line.
crg-grade:
    #!/usr/bin/env bash
    set -uo pipefail
    grade=$(grep -oP '(?<=^\*Current Grade:\* )[A-FX]' docs/status/READINESS.adoc 2>/dev/null | head -1)
    [ -z "$grade" ] && grade="X"
    echo "$grade"

# Print a shields.io CRG badge for embedding in README files
# Looks for '**Current Grade:** X' in READINESS.md; falls back to X
crg-badge:
    #!/usr/bin/env bash
    set -uo pipefail
    grade=$(just crg-grade)
    case "$grade" in
      A) color="brightgreen" ;;
      B) color="green" ;;
      C) color="yellow" ;;
      D) color="orange" ;;
      E) color="red" ;;
      F) color="critical" ;;
      *) color="lightgrey" ;;
    esac
    echo "image:https://img.shields.io/badge/CRG-${grade}-${color}?style=flat-square[CRG ${grade},link=\"https://github.com/hyperpolymath/standards/tree/main/component-readiness-grades\"]"

# Run the full merge-requirement test suite (every category that EXISTS).
#
# `bench` and `readiness` were dependencies here while both were echo-only
# stubs, so this recipe printed "safe to merge!" partly on the strength of two
# echoes. They are now honest (they fail as unimplemented), which is exactly
# why they cannot be dependencies: a merge gate must be composed of checks
# that can pass truthfully. They return here when they do real work — see
# DEBT.md (T-3).
test-all: test e2e aspect
    @echo "All IMPLEMENTED test categories passed (test + e2e + aspect)."
    @echo "Not covered: benchmarks, readiness suite — see DEBT.md (T-3)."

# Run all quality checks
quality: fmt-check lint test
    @echo "All quality checks passed!"

# Fix all auto-fixable issues [reversible: git checkout]
fix: fmt
    @echo "Fixed all auto-fixable issues"

# ═══════════════════════════════════════════════════════════════════════════════
# LINT & FORMAT
# ═══════════════════════════════════════════════════════════════════════════════

# Format all source files [reversible: git checkout]
fmt:
    cargo fmt

# Check formatting without changes
fmt-check:
    cargo fmt --check

# Run linter
lint:
    cargo clippy --all-targets -- -D warnings

# ═══════════════════════════════════════════════════════════════════════════════
# RUN & EXECUTE
# ═══════════════════════════════════════════════════════════════════════════════

# Run the application
run *args: build
    # TODO: Replace with your run command
    echo "Run not configured yet"

# Run with verbose output
run-verbose *args: build
    # TODO: Replace with verbose run command
    echo "Run not configured yet"

# Install to user path
install: build-release
    @echo "Installing sr71_blackglider..."
    # TODO: Replace with your install command

# ═══════════════════════════════════════════════════════════════════════════════
# DEPENDENCIES
# ═══════════════════════════════════════════════════════════════════════════════

# Install/check all dependencies
deps:
    @echo "Checking dependencies..."
    # TODO: Replace with your dependency check
    # Examples:
    #   cargo check
    #   mix deps.get
    #   gleam deps download
    @echo "All dependencies satisfied"

# Audit dependencies for vulnerabilities
deps-audit:
    @echo "Auditing for vulnerabilities..."
    # TODO: Replace with your audit command
    # Examples:
    #   cargo audit
    #   mix audit
    @command -v trivy >/dev/null && trivy fs --severity HIGH,CRITICAL --quiet . || true
    @echo "Audit complete"

# ═══════════════════════════════════════════════════════════════════════════════
# ARRIVAL PACK — agent-facing CLAUDE.md, compiled from a2ml
# ═══════════════════════════════════════════════════════════════════════════════

# Compile CLAUDE.md (the agent arrival pack) from this repo's a2ml
claude-md:
    @bash .machine_readable/arrival-pack/generate.sh

# Fail if CLAUDE.md's generated region drifted from a2ml or was hand-edited
validate-claude-md:
    @bash .machine_readable/arrival-pack/verify.sh

# ═══════════════════════════════════════════════════════════════════════════════
# COAPTATION — typed descriptile↔contractile face-off (homeostasis reading)
# ═══════════════════════════════════════════════════════════════════════════════

# Emit the coaptation receipt: how the descriptiles coapt with the contractiles (SITREP)
coapt:
    @bash .machine_readable/coaptation/coapt.sh --report

# Assemble a re-anchor basis IF the band is red (the drop itself is a human act)
coapt-reanchor:
    @bash .machine_readable/coaptation/coapt.sh --reanchor

# Fail if the committed coaptation receipt drifted from the contractiles/descriptiles
validate-coapt:
    @bash .machine_readable/coaptation/verify.sh

# ═══════════════════════════════════════════════════════════════════════════════
# DOCUMENTATION
# ═══════════════════════════════════════════════════════════════════════════════

# Generate all documentation
docs:
    @mkdir -p docs/generated docs/man
    just cookbook
    just man
    @echo "Documentation generated in docs/"

# Generate justfile cookbook documentation
cookbook:
    #!/usr/bin/env bash
    mkdir -p docs
    OUTPUT="docs/just-cookbook.adoc"
    echo "= sr71_blackglider Justfile Cookbook" > "$OUTPUT"
    echo ":toc: left" >> "$OUTPUT"
    echo ":toclevels: 3" >> "$OUTPUT"
    echo "" >> "$OUTPUT"
    echo "Generated: $(date -Iseconds)" >> "$OUTPUT"
    echo "" >> "$OUTPUT"
    echo "== Recipes" >> "$OUTPUT"
    echo "" >> "$OUTPUT"
    just --list --unsorted | while read -r line; do
        if [[ "$line" =~ ^[[:space:]]+([a-z_-]+) ]]; then
            recipe="${BASH_REMATCH[1]}"
            echo "=== $recipe" >> "$OUTPUT"
            echo "" >> "$OUTPUT"
            echo "[source,bash]" >> "$OUTPUT"
            echo "----" >> "$OUTPUT"
            echo "just $recipe" >> "$OUTPUT"
            echo "----" >> "$OUTPUT"
            echo "" >> "$OUTPUT"
        fi
    done
    echo "Generated: $OUTPUT"

# Generate man page
man:
    #!/usr/bin/env bash
    mkdir -p docs/man
    cat > docs/man/sr71_blackglider.1 << EOF
    .TH sr71_blackglider 1 "$(date +%Y-%m-%d)" "{{version}}" "sr71_blackglider Manual"
    .SH NAME
    sr71_blackglider \- RSR-compliant project
    .SH SYNOPSIS
    .B just
    [recipe] [args...]
    .SH DESCRIPTION
    RSR (Rhodium Standard Repository) project managed with just.
    .SH AUTHOR
    $(git config user.name 2>/dev/null || echo "Author") <$(git config user.email 2>/dev/null || echo "email")>
    EOF
    echo "Generated: docs/man/sr71_blackglider.1"

# ═══════════════════════════════════════════════════════════════════════════════
# CI & AUTOMATION
# ═══════════════════════════════════════════════════════════════════════════════

# Run full CI pipeline locally
# proof-check-all is FATAL if any prover toolchain is absent (idris2/lean/agda/coqc):
# the full CI gate must not pass on a machine that cannot verify the proofs.
ci: deps quality proof-check-all
    @echo "CI pipeline complete!"

# Install git hooks
#
# Delegates to .githooks/install.sh — the ONE hook mechanism in this repo.
# This recipe used to write its own hook into .git/hooks/pre-commit, which
# git never reads once core.hooksPath is set to .githooks (as install.sh
# sets it). It installed a gate that could not fire, then announced
# "Git hooks installed". The hook body now lives in .githooks/pre-commit.
install-hooks:
    @bash .githooks/install.sh

# ═══════════════════════════════════════════════════════════════════════════════
# SECURITY
# ═══════════════════════════════════════════════════════════════════════════════

# Run security audit
security: deps-audit
    @echo "=== Security Audit ==="
    @command -v trivy >/dev/null && trivy fs --severity HIGH,CRITICAL . || true
    @echo "Security audit complete"

# Generate SBOM
sbom:
    @mkdir -p docs/security
    @command -v syft >/dev/null && syft . -o spdx-json > docs/security/sbom.spdx.json || echo "syft not found"

# ═══════════════════════════════════════════════════════════════════════════════
# VALIDATION & COMPLIANCE — see build/just/validate.just
# ═══════════════════════════════════════════════════════════════════════════════

import? "build/just/validate.just"

# ═══════════════════════════════════════════════════════════════════════════════
# STATE MANAGEMENT
# ═══════════════════════════════════════════════════════════════════════════════

# Update STATE.a2ml timestamp
state-touch:
    @if [ -f ".machine_readable/descriptiles/STATE.a2ml" ]; then \
        sed -i 's/last-updated = "[^"]*"/last-updated = "'"$(date +%Y-%m-%d)"'"/' .machine_readable/descriptiles/STATE.a2ml && \
        echo "STATE.a2ml timestamp updated"; \
    fi

# Show current phase from STATE.a2ml
state-phase:
    @grep -oP 'phase\s*=\s*"\K[^"]+' .machine_readable/descriptiles/STATE.a2ml 2>/dev/null | head -1 || echo "unknown"

# ═══════════════════════════════════════════════════════════════════════════════
# GUIX
# ═══════════════════════════════════════════════════════════════════════════════

# Guix recipes — BLOCKED on a foreign package definition. See DEBT.md L-4/C-6.
#
# Two independent faults, neither of which this recipe may paper over:
#
#   1. Both recipes referenced `guix.scm` at the repository ROOT. There is no
#      such file; the only one is build/guix.scm. So neither recipe has ever
#      run, on any machine.
#   2. build/guix.scm is not this project's package. It declares
#      (name "squisher-corpus"), (source #f), gnu-build-system for a Cargo
#      crate, and a PMPL-1.0-or-later licence against this repo's MPL-2.0 —
#      a known estate-wide clobber that reached this repository.
#
# Correcting the path alone would turn a recipe that has never run into one
# that successfully builds SOMEONE ELSE'S package under the WRONG LICENCE.
# That is strictly worse than failing, so these fail with an explanation until
# L-4 is resolved. Fixing guix.scm is owner-only: a licence field is a licence
# edit, and doctrine forbids an agent touching those.
guix-shell:
    #!/usr/bin/env bash
    echo "BLOCKED: build/guix.scm declares (name \"squisher-corpus\") under" >&2
    echo "         PMPL-1.0-or-later; this repository is MPL-2.0." >&2
    echo "         See DEBT.md L-4 (owner-only) and C-6." >&2
    exit 1

guix-build:
    #!/usr/bin/env bash
    echo "BLOCKED: see 'just guix-shell' — build/guix.scm is a foreign package" >&2
    echo "         definition. Building it would produce squisher-corpus." >&2
    echo "         See DEBT.md L-4 (owner-only) and C-6." >&2
    exit 1

# ═══════════════════════════════════════════════════════════════════════════════
# HYBRID AUTOMATION
# ═══════════════════════════════════════════════════════════════════════════════

# Run local automation tasks
automate task="all":
    #!/usr/bin/env bash
    case "{{task}}" in
        all) just fmt && just lint && just test && just docs && just state-touch ;;
        cleanup) just clean && find . -name "*.orig" -delete && find . -name "*~" -delete ;;
        update) just deps && just validate ;;
        *) echo "Unknown: {{task}}. Use: all, cleanup, update" && exit 1 ;;
    esac

# ═══════════════════════════════════════════════════════════════════════════════
# COMBINATORIC MATRIX RECIPES
# ═══════════════════════════════════════════════════════════════════════════════

# Build matrix: [debug|release] x [target] x [features]
build-matrix mode="debug" target="" features="":
    @echo "Build matrix: mode={{mode}} target={{target}} features={{features}}"

# Test matrix: [unit|integration|e2e|all] x [verbosity] x [parallel]
test-matrix suite="unit" verbosity="normal" parallel="true":
    @echo "Test matrix: suite={{suite}} verbosity={{verbosity}} parallel={{parallel}}"

# CI matrix: [lint|test|build|security|all] x [quick|full]
ci-matrix stage="all" depth="quick":
    @echo "CI matrix: stage={{stage}} depth={{depth}}"

# Show all matrix combinations
combinations:
    @echo "=== Combinatoric Matrix Recipes ==="
    @echo ""
    @echo "Build Matrix: just build-matrix [debug|release] [target] [features]"
    @echo "Test Matrix:  just test-matrix [unit|integration|e2e|all] [verbosity] [parallel]"
    @echo "Container:    just container-matrix [build|run|push|shell|scan] [registry] [tag]  (needs container module)"
    @echo "CI Matrix:    just ci-matrix [lint|test|build|security|all] [quick|full]"

# ═══════════════════════════════════════════════════════════════════════════════
# VERSION CONTROL
# ═══════════════════════════════════════════════════════════════════════════════

# Show git status
status:
    @git status --short

# Show recent commits
log count="20":
    @git log --oneline -{{count}}

# Generate CHANGELOG.md with git-cliff
changelog:
    @command -v git-cliff >/dev/null || { echo "git-cliff not found — install: cargo install git-cliff"; exit 1; }
    git cliff --config .machine_readable/configs/git-cliff/cliff.toml --output CHANGELOG.md
    @echo "Generated CHANGELOG.md"

# Preview changelog for unreleased commits (does not write)
changelog-preview:
    @command -v git-cliff >/dev/null || { echo "git-cliff not found — install: cargo install git-cliff"; exit 1; }
    git cliff --config .machine_readable/configs/git-cliff/cliff.toml --unreleased --strip header

# Tag a new release (usage: just release-tag 1.2.3)
release-tag version:
    #!/usr/bin/env bash
    TAG="v{{version}}"
    if git rev-parse "$TAG" >/dev/null 2>&1; then
        echo "Tag $TAG already exists"
        exit 1
    fi
    just changelog
    git add CHANGELOG.md
    git commit -m "chore(release): prepare $TAG"
    git tag -a "$TAG" -m "Release $TAG"
    echo "Created tag $TAG — push with: git push origin main --tags"

# ═══════════════════════════════════════════════════════════════════════════════
# UTILITIES
# ═══════════════════════════════════════════════════════════════════════════════

# Count lines of code
loc:
    @find . \( -name "*.rs" -o -name "*.ex" -o -name "*.exs" -o -name "*.res" -o -name "*.gleam" -o -name "*.zig" -o -name "*.idr" -o -name "*.hs" -o -name "*.ncl" -o -name "*.scm" -o -name "*.adb" -o -name "*.ads" \) -not -path './target/*' -not -path './_build/*' 2>/dev/null | xargs wc -l 2>/dev/null | tail -1 || echo "0"

# Show TODO comments
todos:
    @grep -rn "TODO\|FIXME\|HACK\|XXX" --include="*.rs" --include="*.ex" --include="*.res" --include="*.gleam" --include="*.zig" --include="*.idr" --include="*.hs" . 2>/dev/null || echo "No TODOs"

# Open in editor
edit:
    ${EDITOR:-code} .

# Run high-rigor security assault using panic-attacker
maint-assault:
    @./.machine_readable/scripts/maintenance/maint-assault.sh

# Run panic-attacker pre-commit scan (foundational floor-raise requirement)
#
# This recipe was `cmd -v panic-attack && panic-attack assail . || echo WARN`,
# which exits 0 in BOTH failure modes:
#   * tool absent      -> echoes a warning, reports success;
#   * tool present but SCAN FAILS -> `&&` short-circuits to the `||` branch,
#     the echo succeeds, and the finding is reported as success.
# `just install-hooks` writes `just assail || exit 1` into .git/hooks/pre-commit,
# so the pre-commit security scan could never block a commit — the exact
# "null check that emits reassuring text" scripts/check-proofs.sh was written
# to eliminate. Verified 2026-08-04: panic-attack absent here, `just assail`
# exited 0.
#
# Absence is now fatal by default, matching check-proofs.sh ("a gate that
# cannot run must never report OK"). Set ASSAIL_ALLOW_MISSING=1 to downgrade
# that to a loud skip — an explicit, recorded decision rather than a silent
# default.
assail:
    #!/usr/bin/env bash
    set -euo pipefail
    if command -v panic-attack >/dev/null 2>&1; then
        panic-attack assail .          # exit code propagates — a finding fails the gate
    elif [ "${ASSAIL_ALLOW_MISSING:-0}" = "1" ]; then
        echo "SKIP: panic-attack not installed; ASSAIL_ALLOW_MISSING=1 set — scan NOT run." >&2
    else
        echo "FAIL: panic-attack not found — this gate cannot run, so it must not pass." >&2
        echo "      Install: https://github.com/hyperpolymath/panic-attacker" >&2
        echo "      Or set ASSAIL_ALLOW_MISSING=1 to skip deliberately." >&2
        exit 1
    fi


# Self-diagnostic — checks dependencies, permissions, paths
doctor:
    @echo "Running diagnostics for sr71-blackglider..."
    @echo "Checking required tools..."
    @command -v just >/dev/null 2>&1 && echo "  [OK] just" || echo "  [FAIL] just not found"
    @command -v git >/dev/null 2>&1 && echo "  [OK] git" || echo "  [FAIL] git not found"
    @echo "Checking for hardcoded paths..."
    @grep -rn '$HOME\|$ECLIPSE_DIR' --include='*.rs' --include='*.ex' --include='*.res' --include='*.gleam' --include='*.sh' . 2>/dev/null | head -5 || echo "  [OK] No hardcoded paths"
    @echo "Diagnostics complete."

# Guided tour of key features
tour:
    @echo "=== sr71-blackglider Tour ==="
    @echo ""
    @echo "1. Project structure:"
    @ls -la
    @echo ""
    @echo "2. Available commands: just --list"
    @echo ""
    @echo "3. Read README.adoc for full overview"
    @echo "4. Read EXPLAINME.adoc for architecture decisions"
    @echo "5. Run 'just doctor' to check your setup"
    @echo ""
    @echo "Tour complete! Try 'just --list' to see all available commands."

# Open feedback channel with diagnostic context
help-me:
    @echo "=== sr71-blackglider Help ==="
    @echo "Platform: $(uname -s) $(uname -m)"
    @echo "Shell: $SHELL"
    @echo ""
    @echo "To report an issue:"
    @echo "  https://github.com/metadatastician/sr71-blackglider/issues/new"
    @echo ""
    @echo "Include the output of 'just doctor' in your report."

# ═══════════════════════════════════════════════════════════════════════════════
# FORMAL VERIFICATION (PROOFS) — see build/just/proofs.just
# ═══════════════════════════════════════════════════════════════════════════════

import? "build/just/proofs.just"

# ═══════════════════════════════════════════════════════════════════════════════
# SESSION MANAGEMENT (THIN BINDINGS TO CENTRAL STANDARDS)
# ═══════════════════════════════════════════════════════════════════════════════

# Show canonical session-management command model
session-help:
    @echo "Canonical command model:"
    @echo "  intake repo <path>"
    @echo "  checkpoint change <path>"
    @echo "  verify maintenance <path>"
    @echo "  verify substantial <path>"
    @echo "  verify release <path>"
    @echo "  close planned <path>"
    @echo "  close urgent <path>"
    @echo "  recover repo <path>"
    @echo "  handover full <path>"
    @echo "  handover split <path>"
    @echo "  handover model <path>"
    @echo "  handover human <path>"
    @echo ""
    @echo "Use Just aliases below (thin wrappers around ./session/dispatch.sh)."

# Canonical aliases (friendly recipe names that map to canonical commands)
intake-repo path=".":
    @./session/dispatch.sh intake repo "{{path}}"

checkpoint-change path=".":
    @./session/dispatch.sh checkpoint change "{{path}}"

verify-maintenance path=".":
    @./session/dispatch.sh verify maintenance "{{path}}"

verify-substantial path=".":
    @./session/dispatch.sh verify substantial "{{path}}"

verify-release path=".":
    @./session/dispatch.sh verify release "{{path}}"

close-planned path=".":
    @./session/dispatch.sh close planned "{{path}}"

close-urgent path=".":
    @./session/dispatch.sh close urgent "{{path}}"

recover-repo path=".":
    @./session/dispatch.sh recover repo "{{path}}"

handover-full path=".":
    @./session/dispatch.sh handover full "{{path}}"

handover-split path=".":
    @./session/dispatch.sh handover split "{{path}}"

handover-model path=".":
    @./session/dispatch.sh handover model "{{path}}"

handover-human path=".":
    @./session/dispatch.sh handover human "{{path}}"

secret-scan-trufflehog:
    @command -v trufflehog >/dev/null && trufflehog filesystem . --only-verified || true
