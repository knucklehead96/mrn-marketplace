---
name: setup
description: Install the mrn status line and recommended Claude Code settings (auto mode default, Concise output style, spinner tips and prompt suggestions off, 1h prompt cache) into ~/.claude. Run on demand only.
disable-model-invocation: true
---

Install the mrn status line and recommended settings.

The main thread is chat-only in this plugin, so delegate to the **general-purpose** agent with this task:

> Run `bash "${CLAUDE_SKILL_DIR}/install.sh"` and return its full output verbatim. Do not edit any files yourself.

Then report to the user:
- What changed (the diff printed by the installer), or that everything was already up to date.
- If it failed because `jq` is missing, tell them to install it (e.g. `sudo apt install jq`) and re-run `/setup`.
- Backups: `~/.claude/settings.json.bak` and `~/.claude/statusline.sh.bak` hold the previous versions when anything was replaced.

What gets installed:

| Item | Value |
|---|---|
| Status line | `~/.claude/statusline.sh`: `📁 dir \| model \| ⚡ effort \| ↑in ↓out \| ♻️ cache hit ·TTL left \| 🌑 context % \| ⏳ API time \| 💲 cost`, refreshed every 60s |
| `permissions.defaultMode` | `auto` |
| `outputStyle` | `Concise` |
| `spinnerTipsEnabled` | `false` |
| `promptSuggestionEnabled` | `false` |
| `promptCacheTtl` | `1h` |

Requires `jq`.
