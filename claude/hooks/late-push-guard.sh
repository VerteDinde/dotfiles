#!/bin/bash
# Guards against late-night pushes/PRs and force pushes (any time).
# Reads PreToolUse hook JSON on stdin, may emit a deny decision on stdout.
#
# Bypass sentinels (each auto-expires after 1 hour):
#   touch /tmp/claude-late-ok    — bypass the 9PM–6AM window
#   touch /tmp/claude-force-ok   — bypass the force-push check

set -u

input=$(cat)
cmd=$(printf '%s' "$input" | jq -r '.tool_input.command // ""')

# Bail fast if there's no command (not a Bash call)
[ -z "$cmd" ] && exit 0

# --- Pattern matching ---------------------------------------------------------
# Match anywhere in the command string (handles `cd foo && git push`, etc.).
GATED_RE='(^|[[:space:];&|(])(git[[:space:]]+push|gh[[:space:]]+pr[[:space:]]+(create|merge))([[:space:]]|$)'
FORCE_FLAG_RE='[[:space:]](-f|--force|--force-with-lease)([[:space:]=]|$)'

is_gated=false
is_force=false
if printf '%s' "$cmd" | grep -Eq "$GATED_RE"; then
  is_gated=true
  # Force flags only matter in the context of a git push
  if printf '%s' "$cmd" | grep -Eq '(^|[[:space:];&|(])git[[:space:]]+push' \
     && printf '%s' "$cmd" | grep -Eq "$FORCE_FLAG_RE"; then
    is_force=true
  fi
fi

# Nothing interesting? Allow.
if [ "$is_gated" = false ] && [ "$is_force" = false ]; then
  exit 0
fi

# --- Bypass sentinels ---------------------------------------------------------
# Returns 0 if a sentinel file exists and is younger than 1h; cleans stale ones.
bypass_active() {
  local file=$1
  [ -f "$file" ] || return 1
  local mtime
  mtime=$(stat -f %m "$file" 2>/dev/null || stat -c %Y "$file" 2>/dev/null || echo 0)
  local age=$(( $(date +%s) - mtime ))
  if [ "$age" -lt 3600 ]; then
    return 0
  fi
  rm -f "$file"
  return 1
}

late_bypass=false
force_bypass=false
bypass_active /tmp/claude-late-ok && late_bypass=true
bypass_active /tmp/claude-force-ok && force_bypass=true

# --- Time window: 21:00–05:59 -------------------------------------------------
hour=$((10#$(date +%H)))
is_late=false
if [ "$hour" -ge 21 ] || [ "$hour" -lt 6 ]; then
  is_late=true
fi

# --- Decide -------------------------------------------------------------------
# Force push is checked independently — its own bypass, always gated.
reason=""

if [ "$is_force" = true ] && [ "$force_bypass" = false ]; then
  reason="Force push detected (\`$cmd\`). Force pushes can overwrite remote history irreversibly. Use the AskUserQuestion tool to confirm the user really wants to proceed and understands what will be overwritten. If they confirm, run \`touch /tmp/claude-force-ok\` and retry the command. The bypass auto-expires after 1 hour."
elif [ "$is_gated" = true ] && [ "$is_late" = true ] && [ "$late_bypass" = false ]; then
  reason="It's currently $(date +%H:%M) — between 9PM and 6AM, when this user has asked you to add friction before pushes/PRs (\`$cmd\`). Use the AskUserQuestion tool to ask BOTH of these questions in one call: (1) Would you rather wait until morning to ship this? (2) Have you taken a break recently / are you feeling clear-headed? If they confirm they want to proceed now, run \`touch /tmp/claude-late-ok\` and retry the command. The bypass auto-expires after 1 hour. If they want to wait, stop and suggest picking it up in the morning."
else
  exit 0
fi

jq -n --arg reason "$reason" '{
  hookSpecificOutput: {
    hookEventName: "PreToolUse",
    permissionDecision: "deny",
    permissionDecisionReason: $reason
  }
}'
