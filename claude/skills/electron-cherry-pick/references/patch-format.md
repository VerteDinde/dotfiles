# Electron Patch Format Reference

## Canonical Format

A properly-formatted Electron patch looks like this:

```
From 0000000000000000000000000000000000000000 Mon Sep 17 00:00:00 2001
From: Author Name <author@chromium.org>
Date: Wed, 25 Feb 2026 03:24:19 -0800
Subject: Short description of the change

Optional longer description of the change.
Can be multiple paragraphs.

Bug: 12345678
Change-Id: Iabcdef1234567890abcdef1234567890abcdef12
Reviewed-on: https://chromium-review.googlesource.com/c/chromium/src/+/1234567
Commit-Queue: Author Name <author@chromium.org>
Reviewed-by: Reviewer Name <reviewer@chromium.org>
Cr-Commit-Position: refs/heads/main@{#1234567}

diff --git a/path/to/file.cc b/path/to/file.cc
index abcdef1234567890abcdef1234567890abcdef12..1234567890abcdef1234567890abcdef12345678 100644
--- a/path/to/file.cc
+++ b/path/to/file.cc
@@ -10,7 +10,7 @@ context line
...
```

## Format Rules

### Header
- `From` line: Always zeroed hash (`0000000000000000000000000000000000000000`)
- `From:` (author): Use the original CL author, not your own identity
- `Date:` Use the original CL date
- `Subject:` NO `[PATCH]` prefix — just the plain subject text

### Between Header and Diff
- After the commit message metadata (Bug:, Change-Id:, etc.), there should be a single blank line followed immediately by the first `diff --git` line
- Do NOT include:
  - The `---` separator line
  - The diffstat summary (e.g., `3 files changed, 16 insertions(+), 45 deletions(-)`)
  - Individual file change summaries (e.g., `.../css_unparsed_value.cc | 40 +++++++++----------`)
  - File mode annotations (e.g., `create mode 100644 ...`, `delete mode 100644 ...`)

### Index Lines
- Must use full 40-character blob hashes, NOT abbreviated (13-char) hashes
- Wrong: `index 486e9d10c1e0a..567d4fad7436c 100644`
- Right: `index 486e9d10c1e0a682ec239f4df696f4133300eebb..567d4fad7436c24d4c42bc36ebfd7ee3641e3b90 100644`
- For new files: `index 0000000000000000000000000000000000000000..<hash> 100644`
- For deleted files: `index <hash>..0000000000000000000000000000000000000000`

### Hunk Headers
- `@@` line numbers must match the TARGET Chromium version, not the mainline version
- If a file has different line counts between mainline and the release branch, the hunk offsets need adjustment

### Footer
- Do NOT include the git version footer (`-- \n2.47.0\n` or similar)
- The patch should end with the last line of the last hunk (or newline after it)

## Getting Full Blob Hashes

After applying patches in a test repo, use:
```bash
git diff-tree -r --no-commit-id <commit_hash>
```
Output format: `:old_mode new_mode old_hash new_hash status\tfile`

## Verification

The `apply-patches` CI check will:
1. Apply all patches from `.patches` files
2. Re-export them using `export_all_patches.py`
3. Diff the re-exported patches against the committed patches
4. Fail if there are any differences

If it fails, it provides the exact diff needed as a CI artifact — apply those changes as a `chore: update patches` commit.
