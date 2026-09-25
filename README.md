# mrn-marketplace

A personal [Claude Code](https://claude.com/claude-code) plugin marketplace.

## Plugins

### agents-workflow

Subagent-first orchestration: the main conversation stays chat-only and all work is delegated to dedicated agents.

- **Agents:** `Explore` (search), `general-purpose` (shell/git), `analyst` (root cause), `developer` (code edits), `builder` (builds), `tester` (tests), `review` (code review)
- **Hook:** a PreToolUse hook that blocks file, shell, web, and MCP tools on the main thread and points to the right agent
- **`/setup` skill:** installs a status line and recommended settings into `~/.claude`
- **`/commit` skill:** commits current changes as `<module/file>: title` (≤50 chars) plus a 2-line body (≤80 chars per line)

## Installation

Requires [`jq`](https://jqlang.org) (e.g. `sudo apt install jq`).

In Claude Code:

```
/plugin marketplace add knucklehead96/mrn-marketplace
/plugin install agents-workflow@mrn-marketplace
```

Restart Claude Code, then optionally run `/setup` to install the status line and recommended settings.
