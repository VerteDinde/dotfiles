---
name: electron-cherry-pick
description: Cherry-pick Chromium (or other upstream) CLs into Electron release branches. Handles fetching CL metadata, generating properly-formatted patches, adapting patches to different Chromium versions, and creating PRs. Use when cherry-picking one or more CLs into branches like 40-x-y, 39-x-y, etc.
---

# Electron Cherry-Pick

Cherry-pick one or more upstream Chromium CLs into Electron release branches, producing properly-formatted patches and PRs.

## Input

The user provides:
- One or more Chromium CL URLs (e.g., `https://chromium-review.googlesource.com/c/chromium/src/+/7600415`)
- Target branches (e.g., `40-x-y`, `39-x-y`)
- Optionally: whether this is a security cherry-pick (affects PR labels/format)

## Workflow

### Phase 1: Gather CL Metadata

For each CL, fetch metadata via the Gerrit REST API:

```bash
curl -s 'https://chromium-review.googlesource.com/changes/<CL_NUMBER>/detail?O=916314' | tail -c +5 | python3 -c "
import json, sys
d = json.load(sys.stdin)
rev = d.get('current_revision')
ri = d['revisions'][rev]
cm = ri.get('commit', {})
print('Subject:', d.get('subject'))
print('Status:', d.get('status'))
print('Branch:', d.get('branch'))
print('SHA:', rev)
print()
print('Commit message:')
print(cm.get('message', 'N/A'))
print()
print('Files:', list(ri.get('files', {}).keys()))
"
```

Determine:
- **Dependency order**: Sort by `Cr-Commit-Position` (lower first)
- **File overlap**: If CLs touch the same files, they likely form a dependency chain
- **Commit SHAs**: Verify they exist in the local Chromium repo

### Phase 2: Check Applicability Per Branch

For each target branch:

1. Read `DEPS` to find `chromium_version` (e.g., `144.0.7559.236`)
2. For each file touched by the CLs, compare the release branch version to the pre-CL mainline version:
   ```bash
   diff <(git -C /path/to/chromium show <tag>:<file>) <(git -C /path/to/chromium show <CL_SHA>^:<file>)
   ```
3. If no diff: patches from mainline will apply cleanly
4. If there are diffs: patches need adaptation (see Phase 3b)

### Phase 3a: Generate Patches (Clean Apply)

When patches apply cleanly against the target Chromium version:

```bash
git -C /path/to/chromium format-patch -1 --stdout <SHA>
```

Then fix the format (see Patch Format Requirements below).

### Phase 3b: Generate Patches (Adaptation Needed)

When the target Chromium version differs from mainline:

1. Create a temporary branch at the target Chromium tag:
   ```bash
   git -C /path/to/chromium checkout <tag> -b temp-cherry-pick
   ```
2. Cherry-pick each commit in order:
   ```bash
   git cherry-pick --no-commit <SHA>
   ```
3. **If conflicts arise**: Resolve by applying only changes from THIS CL, not changes from intervening commits between the tag and mainline. The conflict resolution should preserve the tag's version of context while applying the CL's intended change.
4. Commit (only the relevant files — never `git add -A` in the Chromium repo!)
5. Generate the patch from the committed result
6. Reconstruct the patch header with original author, date, and commit message
7. Get full blob hashes using `git diff-tree -r --no-commit-id <commit>`
8. Clean up: switch back and delete temp branch

### Phase 4: Format Patches

See `references/patch-format.md` for the canonical Electron patch format.

Apply these transformations to each generated patch:
1. Zero out the `From` hash: `From 0000000000000000000000000000000000000000 Mon Sep 17 00:00:00 2001`
2. Remove `[PATCH] ` prefix from the `Subject:` line
3. Remove the diffstat block (the `---` + file summary + line counts between commit message and first `diff --git`)
4. Expand all abbreviated index hashes to full 40-character hashes
5. Remove the trailing git version footer (`-- \n2.XX.X\n`)
6. Verify `@@` hunk line numbers match the target Chromium version's file

### Phase 5: Create Branch and Commits

For each target branch:

1. Create branch:
   ```
   git checkout origin/<branch> -b cherry-pick/<branch>/chromium/<descriptive-name>
   ```

2. For each CL (in dependency order), create a separate commit:
   - Copy the patch file to `patches/chromium/cherry-pick-<short-hash>.patch`
   - Append the patch filename to `patches/chromium/.patches`
   - Commit with message:
     ```
     chore: cherry-pick <short-hash> from chromium

     <Original commit subject>

     <Bug/Fixed lines>
     <Change-Id>
     <Reviewed-on>
     <Reviewers>
     <Cr-Commit-Position>

     Co-Authored-By: Claude <svc-devxp-claude@slack-corp.com>
     ```

### Phase 6: Create PR

Push the branch and create a PR.

**Title format:**
- Single CL: `chore: cherry-pick <short-hash> from chromium`
- Multiple CLs: `chore: cherry-pick <N> changes from chromium`

**Body format:**
```markdown
<details>
<summary>cherry-pick <short-hash> from chromium</summary>
<full original commit message including Bug:, Change-Id:, Reviewed-on:, etc.>
</details>

... repeat for each CL ...

Notes: Backported fix(es) for <bug-numbers>.
```

Base branch should match the target (e.g., `40-x-y`).

### Phase 7: Verify

After pushing, monitor the `apply-patches` CI check. If it reports `needs update`:
- The CI provides a diff showing exactly what needs to change
- Common issues: abbreviated hashes, wrong line numbers, missing format fixes
- Apply the fixes, commit as `chore: update patches`, and push

## Important Checks

Before generating patches, verify:
- **Submodule dependencies**: If the CL references APIs from ANGLE, V8, Skia, or other submodules that don't exist in the target branch's pinned version, a companion cherry-pick of the submodule change is also needed
  ```bash
  # Check if an ANGLE commit exists in the pinned version:
  git -C third_party/angle merge-base --is-ancestor <commit> <pinned_revision>
  ```
- **Android/platform-only changes**: Some workarounds are platform-specific (e.g., Android GPU workarounds). If the CL is irrelevant to Electron's platforms, note this to the user

## Reference Examples
- Multi-CL security PR: https://github.com/electron/electron/pull/44255
- Single-CL cherry-pick PR: https://github.com/electron/electron/pull/50441
