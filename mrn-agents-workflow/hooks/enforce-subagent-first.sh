#!/bin/bash
# Subagent-first enforcement (mrn-style): main thread is chat-only.
# Denies Read/Grep/Glob/Edit/Write/Bash and ALL MCP tools (mcp__*) on the
# MAIN thread; allows everything inside subagents.
# Discriminator: hook input carries agent_id only when fired inside a subagent.

INPUT=$(cat)
AGENT_ID=$(echo "$INPUT" | jq -r '.agent_id // empty')
[ -n "$AGENT_ID" ] && exit 0  # inside a subagent — allow

TOOL=$(echo "$INPUT" | jq -r '.tool_name // empty')
TARGET=$(echo "$INPUT" | jq -r '.tool_input.file_path // .tool_input.path // empty')

# Bash carries .tool_input.command, not file_path/path. Silently allow the
# commands the permission system already allowlists (settings.local.json:
# Bash(ps aux *), Bash(ip -br addr)) so this hook doesn't override it.
if [ "$TOOL" = "Bash" ]; then
  COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')
  case "$COMMAND" in
    "ps aux"*|"ip -br addr"*)
      exit 0 ;;
  esac
fi

# Allowlist: config the main thread is allowed to read directly
# (skills, lessons, memory, agents, hooks, output-styles)
case "$TARGET" in
  "$HOME"/.claude/*|"$HOME"/.cursor/skills/*|*/SKILL.md|*/lessons.md)
    exit 0 ;;
esac

printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"mrn-style: main thread is chat-only. Delegate this %s: file reads/searches → Explore; root cause analysis → analyst; code edits → developer; builds → builder; on-target/integration tests → tester; general shell/git → general-purpose."}}\n' "$TOOL"
exit 0
