#!/bin/bash
# Subagent-first enforcement (mrn-style): main thread is chat-only.
# Denies Read/Grep/Glob/Edit/Write/Bash/NotebookEdit and ALL MCP tools (mcp__*)
# on the MAIN thread; allows everything inside subagents.
# Discriminator: hook input carries agent_id only when fired inside a subagent.

if ! command -v jq >/dev/null 2>&1; then
  echo "enforce-subagent-first.sh: jq not found on PATH, failing open" >&2
  exit 0
fi

INPUT=$(cat)
AGENT_ID=$(echo "$INPUT" | jq -r '.agent_id // empty')
[ -n "$AGENT_ID" ] && exit 0  # inside a subagent — allow

TOOL=$(echo "$INPUT" | jq -r '.tool_name // empty')

# Only the tools this hook means to restrict fall through past here. Anything
# else (TaskOutput, TaskStop, Monitor, ...) is allowed on the main thread —
# the harness may invoke this hook for tools outside hooks.json's matcher.
case "$TOOL" in
  Read|Grep|Glob|Edit|Write|Bash|NotebookEdit|mcp__*) ;;
  *) exit 0 ;;
esac

TARGET=$(echo "$INPUT" | jq -r '.tool_input.file_path // .tool_input.path // .tool_input.notebook_path // empty')

# Bash carries .tool_input.command, not file_path/path. Silently allow the
# commands the permission system already allowlists (settings.local.json:
# Bash(ps aux *), Bash(ip -br addr)) so this hook doesn't override it — but
# only plain invocations. A command carrying shell metacharacters (e.g.
# "ps aux; rm -rf x") must never be allowlisted by a prefix match.
if [ "$TOOL" = "Bash" ]; then
  COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')
  case "$COMMAND" in
    *[\;\&\|\$\`\<\>]*|*$'\n'*)
      : ;;  # metacharacters present — do not allowlist, fall through to deny
    "ps aux"*|"ip -br addr"*)
      exit 0 ;;
  esac
fi

# Allowlist: config the main thread is allowed to READ directly (skills,
# lessons, memory, agents, hooks, output-styles). Read-only tools only —
# Edit/Write/NotebookEdit to these paths must still go through a subagent.
# The target is normalized first so "~/.claude/../.ssh/id_rsa" can't pass
# by matching the raw, un-resolved string.
if [ -n "$TARGET" ]; then
  case "$TOOL" in
    Read|Grep|Glob)
      REAL_TARGET=$(realpath -m -- "$TARGET" 2>/dev/null)
      case "$REAL_TARGET" in
        "$HOME"/.claude/*|"$HOME"/.cursor/skills/*|*/SKILL.md|*/lessons.md)
          exit 0 ;;
      esac
      ;;
  esac
fi

printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"mrn-style: main thread is chat-only. Delegate this %s: file reads/searches → Explore; root cause analysis → analyst; code edits → developer; builds → builder; on-target/integration tests → tester; general shell/git → general-purpose."}}\n' "$TOOL"
exit 0
