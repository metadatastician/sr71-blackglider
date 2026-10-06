// SPDX-License-Identifier: MPL-2.0
import { expect, test } from "bun:test";
import { mkdtempSync, mkdirSync, writeFileSync, rmSync } from "node:fs";
import { tmpdir } from "node:os";
import { join, resolve } from "node:path";

const checker = resolve(import.meta.dir, "../../scripts/check-action-pinning.js");
const workflow = ".github/workflows/check.yml";
const otherWorkflow = ".github/workflows/other.yml";
const sha = "a".repeat(40);
const ownLock = (refs) => ({ workflows: { [workflow]: refs } });
const otherLock = (refs) => ({ workflows: { [otherWorkflow]: refs } });

test.each([
  ["accepts the current workflow's lock entry", "actions/checkout@v4", ownLock(["actions/checkout@v4"]), 0],
  ["rejects a ref listed only in another workflow", "actions/checkout@v4", otherLock(["actions/checkout@v4"]), 1],
  ["rejects a ref absent from the current workflow's entry", "actions/checkout@v4", {
    workflows: { [workflow]: ["actions/checkout@v3"], [otherWorkflow]: ["actions/checkout@v4"] },
  }, 1],
  ["rejects a ref with an empty workflow entry", "actions/checkout@v4", {
    workflows: { [workflow]: [], [otherWorkflow]: ["actions/checkout@v4"] },
  }, 1],
  ["rejects dependency-only refs", "actions/checkout@v4", {
    workflows: {}, dependencies: { "actions/checkout@v4": { commit: `sha1-${sha}` } },
  }, 1],
  ["rejects unlocked github-script", "actions/github-script@v7", null, 1],
  ["rejects github-script locked only in another workflow", "actions/github-script@v7", otherLock(["actions/github-script@v7"]), 1],
  ["accepts github-script in its own lock entry", "actions/github-script@v7", ownLock(["actions/github-script@v7"]), 0],
  ["accepts inline github-script SHA", `actions/github-script@${sha}`, null, 0],
  ["rejects refs containing the former exemption", "other/actions/github-script@v7", null, 1],
  ["compares action refs case-insensitively", "SonarSource/scan@v1", ownLock(["sonarsource/scan@v1"]), 0],
  ["accepts subpaths locked by repo root", "github/codeql-action/init@v3", ownLock(["github/codeql-action@v3"]), 0],
  ["rejects subpaths locked only in another workflow", "github/codeql-action/init@v3", otherLock(["github/codeql-action@v3"]), 1],
  ["accepts full subpath refs in their own entry", "github/codeql-action/init@v3", ownLock(["github/codeql-action/init@v3"]), 0],
  ["accepts inline SHAs without a lockfile", `actions/checkout@${sha}`, null, 0],
  ["rejects tags without a lockfile", "actions/checkout@v4", null, 1],
  ["preserves local action exemptions", "./local/action", null, 0],
  ["preserves Docker action exemptions", "docker://alpine:3", null, 0],
  ["preserves expression exemptions", "${{inputs.action}}", null, 0],
])("%s", (_description, ref, lock, exitCode) => {
  const cwd = mkdtempSync(join(tmpdir(), "check-action-pinning-"));
  try {
    mkdirSync(join(cwd, ".github/workflows"), { recursive: true });
    writeFileSync(join(cwd, workflow), `name: Fixture\njobs:\n  check:\n    steps:\n      - uses: ${ref}\n`);
    if (lock !== null) {
      writeFileSync(join(cwd, ".github/workflows/actions.lock"), Bun.YAML.stringify(lock));
    }
    const result = Bun.spawnSync([process.execPath, checker], { cwd });
    expect(result.stderr.toString()).toBe("");
    expect(result.exitCode).toBe(exitCode);
    if (exitCode === 1) {
      expect(result.stdout.toString()).toContain(`${workflow}:5: ${ref}`);
    } else {
      expect(result.stdout.toString()).toContain("all action refs are pinned");
    }
  } finally {
    rmSync(cwd, { recursive: true, force: true });
  }
});
