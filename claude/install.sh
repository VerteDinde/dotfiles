#!/usr/bin/env bash
#
# Install this dotfiles repo's Claude config into ~/.claude by creating
# symlinks. Idempotent — safe to rerun. Backs up any existing real files
# it's about to replace.
#
# Usage: ~/dev/dotfiles/claude/install.sh
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_DIR="${HOME}/.claude"

# Each entry: <source-inside-this-repo>:<target-under-~/.claude>
LINKS=(
  "CLAUDE.md:CLAUDE.md"
  "settings.json:settings.json"
  "skills:skills"
  "hooks/late-push-guard.sh:hooks/late-push-guard.sh"
)

mkdir -p "${CLAUDE_DIR}/hooks"

backup_dir=""
make_backup_dir() {
  [ -n "$backup_dir" ] && return
  backup_dir="${CLAUDE_DIR}/backups/install-$(date +%Y%m%d-%H%M%S)"
  mkdir -p "$backup_dir"
  echo "  backups → $backup_dir"
}

link_one() {
  local src="${SCRIPT_DIR}/$1"
  local dst="${CLAUDE_DIR}/$2"

  if [ ! -e "$src" ]; then
    echo "  skip: $1 (missing in repo)"
    return
  fi

  if [ -L "$dst" ]; then
    local current
    current="$(readlink "$dst")"
    if [ "$current" = "$src" ]; then
      echo "  ok:   $2 → already linked"
      return
    fi
    echo "  relink: $2 (was → $current)"
    rm "$dst"
  elif [ -e "$dst" ]; then
    make_backup_dir
    local backup_path="${backup_dir}/$2"
    mkdir -p "$(dirname "$backup_path")"
    mv "$dst" "$backup_path"
    echo "  backup: $2 → $backup_path"
  fi

  ln -s "$src" "$dst"
  echo "  link: $2 → $src"
}

echo "Installing Claude config from ${SCRIPT_DIR}"
for entry in "${LINKS[@]}"; do
  link_one "${entry%%:*}" "${entry##*:}"
done

echo "Done."
