# Global preferences — Keeley

Cross-project preferences that apply anywhere I'm running Claude. Project-specific rules live in each project's own `CLAUDE.md` and should take precedence when they conflict.

## About me

- Electron maintainer. Primary project: `~/dev/electron/src/electron`.
- I work on both a work machine and a personal machine. This file, along with the rest of `~/.claude/`, is symlinked from `~/dev/dotfiles/claude/` so both machines stay in sync. Treat `~/dev/dotfiles` as a normal git repo — push requires my explicit go-ahead.

## How I like to work

- **Confirm before pushing.** Never run `git push`, `git push --force*`, or `gh pr create` without asking first. I want to build and test locally before anything leaves my machine. This applies to every repo, including dotfiles.
- **Investigate, don't bypass.** If something fails unexpectedly (hook, test, build), trace the root cause before reaching for `--no-verify`, `rm`, or similar shortcuts.
- **Terse beats chatty.** Skip recap summaries when the diff already explains the change. One or two sentences on what changed and what's next is usually enough at the end of a turn.
- **Ask when two plausible approaches both look reasonable.** Propose, get my call, then act — don't silently pick one and discover halfway through that it was the wrong one.

## Security-sensitive work

When I hand you a reported vulnerability to fix, keep commit messages, branch names, and PR copy generic — describe the change as scope/binding/cleanup, never as exploit mechanics. Words to avoid in public-facing copy for security fixes: clickjack, overlay, spoof, bypass, escape, credential capture, exploit.

Backport labels for security fixes normally include the **oldest** active release line in addition to the default bug-fix set; confirm with me before applying `target/<oldest>-x-y` since the label itself can signal severity.

## Dotfiles layout reference

```
~/dev/dotfiles/claude/
├── CLAUDE.md          → ~/.claude/CLAUDE.md
├── settings.json      → ~/.claude/settings.json
├── hooks/
│   └── late-push-guard.sh → ~/.claude/hooks/late-push-guard.sh
└── skills/            → ~/.claude/skills
```

If anything under `~/.claude/` that should be portable is missing from the dotfiles repo, flag it and offer to bring it in.
