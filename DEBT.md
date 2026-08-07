<!--
SPDX-License-Identifier: CC-BY-SA-4.0
SPDX-FileCopyrightText: 2026 Jonathan D.A. Jewell (metadatastician)
-->
# DEBT — SR-71 BlackGlider

**Compiled 2026-08-07** against commit `ce52d18` plus the uncommitted 2026-08-07
workup. Every item below was produced by **running a command**, and the command
is quoted so you can re-run it. Nothing here is inferred from a status document.

This file is an **index**, not a replacement. Detailed ledgers live in
[`docs/status/PROOF-STATUS.adoc`](docs/status/PROOF-STATUS.adoc),
[`docs/status/PROOF-NEEDS.adoc`](docs/status/PROOF-NEEDS.adoc),
[`docs/status/TEST-NEEDS.adoc`](docs/status/TEST-NEEDS.adoc),
[`docs/status/READINESS.adoc`](docs/status/READINESS.adoc) and
[`PROOF-ROADMAP.md`](PROOF-ROADMAP.md). Where they disagree with this file, the
**live run wins** and the contradiction is itself debt.

Anything not confirmed by a run is labelled **DIAGNOSIS (unconfirmed)** rather
than asserted.

**38 items in-repo, plus 7 inherited from upstream.**

| Domain | Count |
|---|---|
| **L** licence | 4 |
| **D** documentation | 5 |
| **C** code | 6 |
| **P** proof | 6 |
| **T** test | 4 |
| **CI** continuous integration | 10 |
| **SC** supply chain | 3 |
| *(U upstream — fix belongs in `rsr-template-repo`)* | *7* |

Regenerate this table with:

```console
$ grep -oE '^### (L|D|C|P|T|CI|SC)-[0-9]+' DEBT.md | sed 's/^### //;s/-[0-9]*$//' | sort | uniq -c
$ grep -cE '^\| U-[0-9]' DEBT.md
```

Keeping the count accurate is not bookkeeping pedantry: a register that
miscounts itself is the same failure mode as a status doc that miscounts the
tests, which is most of what is listed below.

| Severity | Meaning |
|---|---|
| **HIGH** | Misleads a reader about what is verified, or blocks the next real step |
| **MEDIUM** | Real defect, contained, no false claim escapes |
| **LOW** | Cosmetic, or correctly-labelled scaffolding |

---

## L — Licence

> Estate doctrine 6: **no automated licence edits, ever** — manual, owner-only.
> Every item in this section is therefore an *owner action*, deliberately left
> unmade.

### L-1 · HIGH · An AGPL licence text ships in a repo whose own policy bans AGPL
`LICENSES/AGPL-3.0-or-later.txt` is present and referenced by nothing.

```console
$ reuse lint | grep -A1 'Unused licenses'
* Unused licenses: AGPL-3.0-or-later
* Used licenses: CC-BY-SA-4.0, MPL-2.0
```

The repository bans AGPL in four independent places —
`.machine_readable/compliance/rust/deny.toml:39` denies it,
`.machine_readable/descriptiles/AGENTIC.a2ml:24` says "Never use AGPL",
`.github/copilot-instructions.md:18` repeats it, and
`.github/workflows/rhodibot.yml:67` actively warns when a file carries an
AGPL header. Shipping the text invites exactly the misreading the policy
exists to prevent.

**Next:** owner deletes `LICENSES/AGPL-3.0-or-later.txt`. Not done here:
doctrine 6 forbids an agent touching licence files.

### L-2 · MEDIUM · REUSE lint fails; roughly half of tracked files carry no copyright
```console
$ reuse lint | grep 'Files with copyright'
* Files with copyright information: 224 / 453
```
229 files have neither `SPDX-FileCopyrightText` nor an entry in
`.machine_readable/compliance/reuse/dep5`. Includes `Cargo.toml`,
`CITATION.cff`, `.github/funding.yml` and every `.gitkeep`.

**Next:** owner extends `dep5` with blanket paragraphs for generated and
config files rather than stamping 229 headers by hand. **Caution** — an estate
incident is on record where a blind SPDX-header sweep mis-licensed files by
inserting a header above an existing one; headers must be *moved*, never
imposed, and only after grepping the whole file.

### L-4 · HIGH · `build/guix.scm` declares a **different project** under a **different licence**
```console
$ grep -nE 'name|license' build/guix.scm
10:  (name "squisher-corpus")
17:  (license ((@@ (guix licenses) license) "PMPL-1.0-or-later"
18:             "https://github.com/hyperpolymath/palimpsest-license")))
$ grep -n '^license' Cargo.toml
5:license = "MPL-2.0"
```
The package definition names **`squisher-corpus`**, not this project, and
declares **PMPL-1.0-or-later** against a repository that is MPL-2.0. It also
sets `(source #f)` and `gnu-build-system` for a Cargo crate. This is a known
estate-wide clobber — a single `guix.scm` copied across many repositories —
and it reached this one.

`.github/workflows/guix-policy.yml` never caught it because that gate checks
for the *presence* of a `guix.scm` and the *absence* of Nix; it never reads the
package's identity or builds anything.

**Next:** owner-only, per doctrine 6 — a licence field is a licence edit.
Either write a real package definition for this crate or delete the file. Until
then, no reproducible-build claim can stand (which is why the capability was
removed from `rsr-profile.a2ml`).

### C-6 · MEDIUM · `just guix-shell` / `just guix-build` point at a path that does not exist
```console
$ grep -n 'guix.scm' Justfile
452:    guix shell -D -f guix.scm
456:    guix build -f guix.scm
$ ls guix.scm
ls: cannot access 'guix.scm': No such file or directory   # it is at build/guix.scm
$ command -v guix
(nothing — guix is not installed)
```
Both recipes reference the repository root; the only `guix.scm` is under
`build/`. Deliberately **not** "fixed" by correcting the path: doing so would
make `just guix-build` successfully attempt to build the foreign
`squisher-corpus` package described in L-4. The recipes now fail with an
explanation instead. Correct the path only once L-4 is resolved.

### L-3 · LOW · The dual-licence split is correct but undocumented at the root
Code is MPL-2.0 (`Cargo.toml:5`), docs are CC-BY-SA-4.0. Both texts are
present and used. Nothing at the repository root states the split; a reader
sees `LICENSE` (MPL-2.0) and may assume it governs the prose too.

**Next:** one sentence in `README.adoc`. Low risk, low effort.

---

## D — Documentation

### D-1 · HIGH · `AFFIRMATION.adoc` — the honesty file — was itself an unfilled template
Its title read `= AFFIRMATION — SR-71 BlackGlider, as of <UTC timestamp>`, its
claims table held three `_e.g._` examples, and its anchor fields were
`<full commit SHA at time of signing>`. The one document whose entire purpose
is dated, evidence-backed, falsifiable claims made none.

**Status: FIXED 2026-08-07** — rewritten from measured runs and anchored to a
real SHA, timestamp and toolchain list.

### D-2 · MEDIUM · Status ledgers described a world that no longer existed
`PROOF-STATUS.adoc` reported 2 of 7 Idris2 obligations proven with 4 blocked,
while the MANIFEST quarantine was empty and all 7 passed. `TEST-NEEDS.adoc`
called Coq "UNWIRED" and Zig "0 tests". `READINESS.adoc` pinned the whole
project at grade E on two blockers that had both cleared.

**Status: FIXED 2026-08-07.** The recurrence risk is structural, not
clerical — see CI-1: nothing recomputes these from a run.

### D-3 · MEDIUM · `.gitlab-ci.yml` declares itself the source of truth for CI that does not exist
```console
$ head -3 .gitlab-ci.yml          # "Primary CI/CD — GitLab is the source of truth"
$ git remote -v                   # origin github.com:metadatastician/... only
```
No GitLab remote exists, so the file has never run. It also covers none of the
proofs, the Zig seam, or `just`.

**Next:** delete it, or add the GitLab remote and make it real. Leaving a file
that claims primacy over the CI that actually runs is the more expensive option.

### D-4 · LOW · Root-level `docs/wikis/README.adoc` predates an actual wiki
The GitHub wiki was enabled but empty until 2026-08-07. Cross-check the two
now that wiki pages exist.

### D-5 · LOW · `docs/` carries ~20 template `README.adoc` stubs
`docs/theory/{computing,formalisms,mathematics,ontologies,other}/README.adoc`,
`docs/whitepapers/{academic,industry,outreach}/README.adoc` and siblings are
RSR scaffolding describing what *could* live there. Harmless, but they inflate
the apparent documentation surface.

**Next:** keep (they are correctly-labelled scaffolding) or prune. Decide once.

---

## C — Code

### C-1 · HIGH · `scripts/validate-template.sh` is ungated **and currently red**
```console
$ bash scripts/validate-template.sh . 0 >/dev/null 2>&1; echo $?
1
$ bash scripts/validate-template.sh . 0 2>&1 | grep ERROR
ERROR: Required workflow missing: codeql.yml
```
410 lines. It demands `codeql.yml`, deliberately deleted in `ce52d18` when
GitHub's *default* CodeQL setup took ownership of scanning (default setup
rejects SARIF from an advanced config). Its only caller is
`benches/template_bench.sh`, which discards the exit code.

**Next:** update its required-workflow list to match `ce52d18`, then either
wire it into `just validate` or delete it. A 410-line red validator that only a
dead benchmark calls is worse than no validator.

### C-2 · MEDIUM · `benches/template_bench.sh` benchmarks a deleted file and discards every exit code
```console
$ ls tests/e2e/
ls: cannot access 'tests/e2e/': No such file or directory
```
`benches/template_bench.sh:165` guards on that path, so BENCHMARK 5 has been
silently skipped since the e2e harness was re-instantiated — while still
printing its banner. Every timed command ends `|| true`, so a broken subject is
timed as a fast success (it currently times `validate-template.sh`, which
exits 1 — see C-1).

**Next:** delete BENCHMARK 5, drop the `|| true`, and either wire the script in
or remove it.

### C-3 · MEDIUM · The Zig FFI is a template surface, not this project's FFI
`src/interface/ffi/src/main.zig` exports `sr71_blackglider_init/process/...` —
generic handle-and-buffer scaffolding. It now compiles and has 11 passing tests
(it previously did neither), but it exposes no Conway concept: no world, no
generation, no glider. Nothing in the Rust kernel calls it.

**Next:** either give it a real surface over the kernel, or mark it explicitly
as an unconsumed seam. Tests passing is not the same as a seam being used.

### C-4 · LOW · `just doctor` cannot fail, and one branch is unreachable
Every check prints `[OK]`/`[FAIL]` and returns 0. Its hardcoded-path grep is
inverted: when it *finds* paths it prints them and succeeds; the
"No hardcoded paths" branch is only reachable when grep fails.

**Next:** acceptable for a diagnostic, but the `[FAIL]` labels imply gating
that does not happen. Either exit non-zero on `[FAIL]` or rename them.

### C-5 · LOW · `mise.toml` pins rust/just/zig but not the four provers
`just test` now treats a missing prover as fatal, so an unpinned prover is a
reproducibility gap in the golden path itself.

**Next:** pin idris2/coq/agda/lean, or document that they come from `pack`/`elan`.

---

## P — Proof

### P-1 · HIGH · Three of the four prover suites prove nothing about this project
`verification/proofs/coq/TypeSafety.v`, `agda/Properties.agda` and
`lean4/ApiTypes.lean` are verbatim RSR template exemplars — a toy `TyNat/TyBool`
type system, list-append length preservation, and a `Result` functor. They
compile, they are gated, and their green says nothing about Conway physics.

```console
$ head -3 verification/proofs/coq/TypeSafety.v
(* Coq Proof Template: Type system soundness
   Replace with your project's type system proofs. *)
```

This is the highest-risk item in the file: a reader seeing "four provers, all
green" will reasonably over-read it. The Idris2 MANIFEST is already honest in
this style for `Types.idr` ("template examples, honest ones").

**Next:** instantiate them with real obligations, or label them exemplars in
`PROOF-STATUS.adoc` — done 2026-08-07 — and keep the label until they carry
real content.

### P-2 · HIGH · No refinement connects the Idris2 model to the Rust kernel
The constitution is proved in Idris2; the kernel is exhaustively tested in
Rust. **Nothing proves the two agree.** A divergence between model and
implementation would leave both ledgers green.

**Next:** the standing entry in `STATE.a2ml [blockers-and-issues]`. Realistic
first step is extraction or a shared vector corpus, not full refinement.

### P-3 · MEDIUM · The Idris2 ABI modules prove properties of a *model*, not of the shipped FFI
```console
$ grep -rn 'CABICompliant\|StructLayout' --include='*.zig' --include='*.rs' .
(no matches)
```
No Rust or Zig struct is ever presented to `CABICompliant`; the only inhabitant
in-tree is `emptyStructCompliant` for a fieldless struct. Neither phrasing of
`FieldAligned` requires alignment to be a power of two, nor ties
`fieldAlignment` to any real type's natural alignment.

**Next:** do not quote these modules as "the C ABI is proven compliant". To make
them bind, generate `StructLayout` values from the actual FFI types.

### P-4 · MEDIUM · `verification/proofs/tlaplus/StateMachine.tla` is unwired *and* off-topic
```console
$ bash scripts/check-proofs.sh tlaplus
usage: check-proofs.sh <idris2|lean4|agda|coq>   # exit 2
```
No MANIFEST, no gate mode, no TLA+ toolchain installed. The spec models a
generic request pipeline (`idle → scanning → routing → dispatching`) — there is
no such protocol in this project.

**Next:** delete it, or add a `tlaplus` mode and instantiate it for the frozen
mission state machine when that exists. Deleting is the honest default.

### P-5 · MEDIUM · Near-miss on record: the divisibility restatement was briefly *weaker*
Restating `FieldAligned` as `(k ** offset = k * alignment)` without a `NonZero`
conjunct admitted `alignment = 0`, and a complete `CABICompliant` certificate
could be built for a size-0/alignment-0 struct that cannot exist in C. The old
mod phrasing could not even be *formed* at alignment 0, which in a total type
theory means uninhabited — i.e. strictly stronger.

Caught by adversarial review, not by the gate. **Fixed**: `NonZero` conjunct
added; the attack is now rejected (`Mismatch between: S ?x and 0`) while legal
layouts still prove.

**Next:** kept here deliberately. A repair that weakens a statement is the
failure mode this project most needs to keep visible.

### P-6 · LOW · `%default total` is enforced, but totality of the *kernel* is not proved
The Rust kernel has no termination argument beyond bounded loops.

---

## T — Test

### T-1 · HIGH · Exhaustion is over *finite* domains and must not be read as general proof
512/512 local rule configurations and 65,536/65,536 4×4 worlds are complete
**for those domains**. Nothing establishes behaviour on larger worlds beyond the
240-generation Snark trace.

**Next:** state the domain wherever the numbers appear (done in
`PROOF-STATUS.adoc` and `README.adoc`).

### T-2 · MEDIUM · `src/lib.rs` has zero unit tests
```console
$ cargo test --all-targets 2>&1 | grep 'test result'
test result: ok. 0 passed; ...   # src/lib.rs
```
All 12 tests are integration tests. Internal invariants are exercised only
through the public surface.

### T-3 · MEDIUM · No benchmark suite and no readiness suite
`just bench` and `just readiness` were echo-only stubs that printed success;
`just test-all` depended on both and announced "safe to merge". They now exit 1
as unimplemented and have been removed from `test-all`.

**Next:** add a real `cargo bench` over `Life::step`, or drop the recipes.

### T-4 · LOW · No fuzz harness
`tests/fuzz/README.adoc` is a scaffold. Lower value than it looks: the 4×4
domain is already exhaustive, so fuzzing only adds value at larger world sizes.

---

## CI — Continuous integration

### CI-1 · HIGH · Until 2026-08-07 **no workflow ran any proof gate, the Zig tests, or `just test`**
```console
$ grep -rn 'check-proofs\|proof-check\|just test' .github/workflows/
(no matches)
```
The only CI path touching proofs was `e2e.yml → tests/e2e.sh`, whose prover
loop was `command -v <tool> || skip`, and no workflow installed any prover. On
a bare runner that scored `PASS=0 FAIL=0 SKIP=4` and exited 0 — verbatim the
hole `scripts/check-proofs.sh`'s own header was written to close ("a MISSING
TOOLCHAIN reported success"). Worse, `e2e.yml`'s `paths:` filter omitted
`verification/**`, so a proof change did not even trigger it.

**Status: ADDRESSED 2026-08-07** — new `.github/workflows/proof-gate.yml`
installs each prover and runs each gate; `tests/e2e.sh` now treats a missing
prover as **fatal under CI** and a skip only locally; `e2e.yml` path filters
widened. **Unproven until it runs** — see CI-3.

### CI-2 · HIGH · Nothing is required to merge
`.github/settings.yml` now sets `contexts: []`, and probot/settings is not
installed on the org (`gh api .../branches/main/protection` → 404, "Branch not
protected"). Every gate is advisory.

The previous value was worse: it required `estate-audit`, a context **nothing
emits** (`gh api .../check-runs` confirms), together with `enforce_admins` — a
branch nothing could ever merge into — plus an approving review a solo
maintainer cannot give.

**Next:** once `proof-gate.yml` has a green run, add its job names one at a
time, each verified present in `check-runs` output *before* being required.

### CI-3 · MEDIUM · `proof-gate.yml` installs provers from distribution packages — versions may drift
The MANIFESTs were ground-truthed against idris2 0.7.0, coqc 8.20.1, Agda
2.6.4.3, Lean 4.32.2. `apt` may ship different versions. Each job prints
`--version` first so a drift failure is diagnosable from the log.

**CONFIRMED 2026-08-07, and it found a real portability defect.** `apt` does
not carry `idris2` on the runner image at all (`E: Unable to locate package
idris2`); the job now uses the `idris2-pack` container. With that in place the
gate ran and *failed on a genuine difference between builds*:

```console
Error: While processing right hand side of FieldAligned.
       Data.Nat.NonZero is not accessible in this context.
```

`FieldAligned` is `public export`, so every name in its right-hand side must be
`public export` too — and `Data.Nat.NonZero`'s visibility differs between the
local idris2 0.7.0 and the image's build. Fixed by declaring a local
one-constructor `NonZeroAlign` predicate in `ABI/Layout.idr` instead of
borrowing one whose export annotation this repo does not control. The
alignment-0 attack is still rejected and legal layouts still prove.

**This is the value of running a gate in a second environment**: a proof that
compiles on one machine is not a portable proof, and only CI could show it.

### CI-4 · MEDIUM · Receipt and generated-file drift is caught by nothing
`just validate-coapt` fails on a clean tree (the committed coaptation receipt
is stale relative to the contractiles), and neither it nor
`just validate-claude-md` runs in CI or in a hook.

**Next:** regenerate and commit the receipt, then wire both into pre-push or CI.

### CI-5 · MEDIUM · `panic-attack` never executes on either side
The pre-commit hook degrades to a loud skip when the tool is absent (it is),
and the CI `static-analysis-gate.yml` installer does not resolve. `just assail`
previously exited 0 both when the tool was missing **and when the scan failed**;
it now propagates the real exit code and treats absence as fatal by default.

**Next:** publish or vendor a resolvable `panic-attack` install, or drop the gate.

### CI-6 · LOW · `SONAR_TOKEN` unset; SonarCloud project not minted; OpenSSF BP not registered
`sonarqube.yml` reports itself unconfigured and exits 0 — honest by design.
The README carries an OpenSSF Best Practices badge with no registered project.

### CI-8 · HIGH · The Hypatia security scan reported "clean" whenever it crashed — and now fails, correctly
`static-analysis-gate.yml` captured the scanner's exit code into `HYP_EXIT`
and then never read it (shellcheck SC2034 flagged the variable as unused —
that warning *was* the bug report). When the scanner produced no parseable
JSON the step wrote `[]` and continued, so a **crashed scan and a genuinely
clean scan were indistinguishable**, and the crash was the one that looked
better.

`HYP_EXIT` is now load-bearing: no parseable JSON *and* a non-zero exit fails
the step with the scanner's own output. On the first run after the fix, the
job went **red** — which is the correct, informative outcome and the reason
the fix was worth making.

**Status:** the *gate* is fixed. The underlying scanner failure is now visible
and is real, open work.

**Next:** read the failing step's output on the newest `Static Analysis Gate`
run and fix the scanner invocation (or the Hypatia install) it exposes. Do not
restore the `[]` fallback.

### CI-9 · MEDIUM · `proof-gate.yml` needed three install fixes on its first real run
Recorded because the first run is the only honest test of a new gate, and it
found three separate defects the local runs could not:

* *Agda* — `agda` alone is not enough. `Properties.agda` opens `Data.Nat`,
  `Data.List` and `Relation.Binary.PropositionalEquality`, all from
  **agda-stdlib**, a separate package that also needs `~/.agda/libraries`
  pointed at its `.agda-lib`. The gate ran and failed on the imports: correct
  behaviour, wrong workflow.
* *Lean* — `elan-init.sh --default-toolchain none` installs elan but no Lean;
  the next step died with "no default toolchain configured". Now installs the
  toolchain **read from `verification/proofs/lean4/lean-toolchain`** so the
  pin cannot drift from the workflow.
* *Idris2* — not in the runner image's apt sources at all
  (`E: Unable to locate package idris2`), and there is no first-party setup
  action. Now runs in the `ghcr.io/stefan-hoeck/idris2-pack` container.

**Next:** confirm all four jobs green, then require them in branch protection
(CI-2). Coq passed on the first attempt and needs nothing.

### CI-10 · MEDIUM · The Agda job is RED: Ubuntu's `agda-stdlib` ships no `.agda-lib`
The only proof job still failing, and left red deliberately rather than
softened. Measured on the runner (`ubuntu-24.04`, Agda 2.6.3):

```console
$ dpkg -L agda-stdlib | grep '\.agda-lib$'
(nothing)
$ cat ~/.agda/libraries
(empty)
# and from the gate itself:
Library 'standard-library' not found. ... Installed libraries: (none)
```

`apt-get install agda agda-stdlib` succeeds and installs Agda 2.6.3, but the
package registers no `.agda-lib`, so Agda cannot resolve
`standard-library` — which `Properties.agda` needs for `Data.Nat`,
`Data.Nat.Properties`, `Data.List`, `Data.List.Properties` and
`Relation.Binary.PropositionalEquality`. Neither `/etc/agda/libraries` nor a
`dpkg -L` lookup produced a path.

This is a *packaging* problem, not a repository problem — and it is worth
noting the gate behaved correctly throughout: it refused to pass, said exactly
what was missing, and told us where to register it.

**Why it stays red:** the alternative is a skip, and a skipped Agda gate is
indistinguishable from a passing one — the precise defect CI-1 was raised to
remove. Red-and-recorded beats green-and-lying. Nothing is required to merge
(CI-2), so this blocks no one.

**Next:** stop using `apt` for the stdlib. Fetch a tagged `agda-stdlib`
release matching the Agda on the runner (2.6.3 pairs with the v1.7.x line),
unpack it, and write its `standard-library.agda-lib` path into
`~/.agda/libraries`. Pin the release tag. Alternatively pin Agda itself via
`haskell-actions/setup` (already SHA-pinned in this repo) and build the stdlib
from a pinned tag.

**Value note, so this is prioritised honestly:** `Properties.agda` is a
template exemplar (it proves `length (xs ++ ys) ≡ length xs + length ys`) — see
P-1. Getting this job green raises CI *hygiene*, not assurance about Conway
physics. It sits below P-1 and P-2 in real importance.

### CI-7 · LOW · `just test` is now fatal-if-a-prover-is-absent, which makes the golden path heavy
Contributors need four provers plus Zig to run `just test`. This is deliberate
(no silent green), but it raises the barrier to a first contribution.

**Next:** consider `just test-fast` for the cargo+zig subset, clearly labelled
as *not* the golden path.

---

## SC — Supply chain

### SC-1 · MEDIUM · `proof-gate.yml` installs Lean via an unpinned `curl | sh`
```yaml
curl -sSfL https://raw.githubusercontent.com/leanprover/elan/master/elan-init.sh
```
A deliberate exception to the estate's SHA-pinning rule, which governs GitHub
Actions. The *toolchain* is pinned by `verification/proofs/lean4/lean-toolchain`;
what is unpinned is the **installer**, fetched from `master`.

**Next:** pin to a tagged elan release with a checksum, or use a SHA-pinned
setup action.

### SC-2 · LOW · Action pins are verified, but two required a rename chase
30 of 32 `uses:` SHAs resolved on first check. The two failures —
`hyperpolymath/{a2ml,k9}-validate-action` — were repos absorbed into
`*-ecosystem`; Actions does not follow repo renames. Re-pinned and verified.

### SC-3 · LOW · Zero external Rust dependencies — recorded as an asset
`Cargo.toml` declares no `[dependencies]`. There is no `cargo audit` surface
because there is nothing to audit. Worth stating so a future dependency is a
conscious decision.

---

## Upstream — defects inherited from `rsr-template-repo`

Confirmed present at upstream `hyperpolymath/rsr-template-repo` live `main`
(`c250e66`, verified 2026-08-07 against a fresh clone). **No open issue or PR
covers any of them** — all 23 issues/PRs ever filed were enumerated.

| # | Defect | Upstream |
|---|---|---|
| U-1 | `build.zig` declares no steps: `zig build` compiles nothing, `zig build test` errors | present |
| U-2 | `main.zig` does not compile — opaque type with fields; `c_allocator` without libc; `callconv(.C)` | present |
| U-3 | `check-no-placeholders.sh` dies at exit 1 with **zero output** in any remoteless checkout | present |
| U-4 | `ApiTypes.lean` binder named `max` never binds; has never compiled | present |
| U-5 | All five Idris2 ABI modules still quarantined | present |
| U-6 | `tests/e2e.sh` runs the template's own instantiation smoke test | present |
| U-7 | Upstream CI runs neither `zig build test` nor any proof gate — green but blind | present |

Every repository minted from that template inherits all seven.

**Next:** file upstream. Deliberately **not** done from here — it is an
outward-facing action on another repository and is the owner's call.

---

## What is NOT debt

Stated so it is not "fixed" by a later sweep:

- **`sonarqube.yml` exiting 0 when unconfigured** is correct. It reports its
  own state rather than failing over a missing secret.
- **`just bench` / `just readiness` exiting 1** is correct. They are
  unimplemented and now say so, rather than printing success.
- **Root `/build/` being tracked** is correct. It holds `just` imports the root
  `Justfile` depends on; it is not an artifact directory.
- **`verification/proofs/idris2/Types.idr` being a template example** is
  correct *and already labelled* in the MANIFEST. It is the model for how P-1
  should be resolved.
