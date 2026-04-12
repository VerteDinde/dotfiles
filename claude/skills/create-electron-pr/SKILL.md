---
name: create-electron-pr
description: Draft and open a pull request against electron/electron using the project's PR template, `Notes:` release-note convention, and Keeley's semver/target labeling rules. Use when opening any PR in ~/dev/electron/src/electron (or any electron/electron checkout), especially after a commit that's ready to ship. Covers template-correct body, label selection, security-sensitive framing, and the confirm-before-push rule.
---

# Create an Electron pull request

Use this skill whenever you're about to run `gh pr create` in an `electron/electron` checkout. It exists because the template is mandatory, the labels matter, and I've made mistakes here before.

## Before you start

1. **Never push or open a PR without explicit go-ahead from Keeley.** She wants to build and test locally first. This rule holds even when the work looks "done." Ask.
2. Confirm the branch is pushed (`git push -u origin <branch>`), that the diff matches what you expect, and that any relevant spec tests have been run.
3. Read the project `CLAUDE.md` at `~/dev/electron/src/electron/CLAUDE.md` — it has authoritative PR, labeling, and backport rules. This skill layers Keeley's personal preferences on top; when in doubt, the project `CLAUDE.md` wins.

## Template (required — PRs without it are auto-closed)

The template lives at `.github/PULL_REQUEST_TEMPLATE.md`. It has three sections that must appear, in this order:

```markdown
#### Description of Change

<1–3 short paragraphs explaining what changed and why. Bullet points are fine.
Describe the change from the reader's perspective, not your thought process.>

#### Checklist

- [x] PR description included
- [x] I have built and tested this PR
- [x] `npm test` passes
<Remove any checklist items that don't apply. Use [x] only for ones that are true.>

#### Release Notes

Notes: <one-line app-developer-facing description, capitalized, past-tense, punctuated; or "Notes: none">
```

Pass the body to `gh pr create --body "$(cat <<'EOF' ... EOF)"` so formatting stays intact.

## `Notes:` line — the release note

- Always present as the **last line** of the body. This is consumer-facing release-note copy pulled by Clerk.
- Capitalized, past tense, punctuated. Examples: `Notes: Fixed an issue where ...`, `Notes: Added support for ...`.
- If the change has no user-visible impact (refactor, CI, build tweak, internal docs): `Notes: none`.
- Describe the **user-visible** behavior, not the implementation. A reader should be able to understand what changed without knowing the code.

## Labels (only when Keeley has write access to electron/electron)

### Semver

Pick exactly one:

- `semver/none` — build changes, refactors, CI, internal docs — anything with no end-user impact
- `semver/patch` — backwards-compatible bug fixes
- `semver/minor` — backwards-compatible new functionality
- `semver/major` — incompatible API changes

### Backport targets

Find active targets at PR time — label colors tell you which are active:

```bash
gh label list --repo electron/electron --search target/ --json name,color --jq '.[] | select(.color == "ad244f") | .name'
```

Default policy:

- **Bug fixes (`semver/patch`)** — backport to all active release lines **except the oldest**.
- **Security fixes** — backport to **all** active release lines including the oldest. BUT see the security-framing note below: adding `target/<oldest>-x-y` on a public PR can itself signal severity. For security work, confirm with Keeley before applying the oldest-line label; in many cases the oldest backport goes through the private security channel instead.
- **Features (`semver/minor`) and breaking changes (`semver/major`)** — no backport labels; main-only by default.

Apply labels at `gh pr create` time with repeated `--label` flags, e.g.:

```bash
gh pr create \
  --title "..." \
  --label "semver/patch" \
  --label "target/40-x-y" \
  --label "target/41-x-y" \
  --label "target/42-x-y" \
  --body "$(cat <<'EOF'
... template ...
EOF
)"
```

## Security-sensitive framing

When the underlying work is a reported vulnerability (this happens reasonably often), the PR copy should **not** describe the exploit. Frame it as cleanup, scoping, or a binding refactor. Words to **avoid** in public-facing copy: clickjack, overlay, spoof, bypass, escape, credential capture, exploit, takeover, hijack, privilege.

Good patterns: "only bind X on primary main frames", "restrict Y to its legitimate caller", "scope Z to the frame where it's actually used", "tighten input validation on the N boundary". Describe **what** the scope now is, not **why** the old scope was wrong.

The `Notes:` line should also be generic — e.g. `Notes: Fixed an issue where X could be reached from frames other than the primary main frame.` — not `Notes: Fixed a clickjacking vulnerability in X.`

## Title conventions

- Short — under 70 characters. Details go in the body.
- Conventional-commit prefix matching recent history: `fix:`, `feat:`, `refactor:`, `chore:`, `perf:`, `docs:`, `test:`, `build:`, `ci:`. Check `git log --oneline -10` to match style.
- Lowercase after the colon unless the first word is a proper noun (class name, API name).
- Don't repeat the prefix in the body's first line.

## Workflow (paste-friendly)

```bash
# 0. Confirm Keeley has green-lit the push.
# 1. Make sure the branch is up to date:
git status
git push -u origin "$(git rev-parse --abbrev-ref HEAD)"

# 2. Gather label info:
gh label list --repo electron/electron --search target/ \
  --json name,color \
  --jq '.[] | select(.color == "ad244f") | .name'

# 3. Open the PR with template-correct body:
gh pr create \
  --title "fix: ..." \
  --label "semver/patch" \
  --label "target/..." \
  --body "$(cat <<'EOF'
#### Description of Change

... 1-3 paragraphs ...

#### Checklist

- [x] PR description included
- [x] I have built and tested this PR
- [x] `npm test` passes

#### Release Notes

Notes: ...
EOF
)"
```

## Common mistakes to not repeat

- Forgetting the `#### Description of Change` / `#### Checklist` / `#### Release Notes` section headers — the template check will fail and the PR may be auto-closed.
- Putting the `Notes:` line anywhere other than the last line of the body.
- Writing a PR summary in conversation style ("So I was looking at this and...") instead of describing the finished change.
- Marking checklist items `[x]` that aren't actually true (e.g., "`npm test` passes" when you haven't run it).
- Revealing exploit mechanics in security-fix PRs.
- Adding backport labels without checking which release lines are currently active.
- Running `gh pr create` before Keeley has said "go ahead" — confirm first, always.
