#!/bin/bash
# Installs the mrn status line and recommended settings into ~/.claude. Safe to re-run.
set -euo pipefail

here=$(cd "$(dirname "$0")" && pwd)
claude_dir="$HOME/.claude"
settings="$claude_dir/settings.json"

command -v jq >/dev/null 2>&1 || { echo "ERROR: jq is required (e.g. sudo apt install jq)" >&2; exit 1; }
mkdir -p "$claude_dir"
[ -f "$settings" ] || echo '{}' > "$settings"
jq empty "$settings" || { echo "ERROR: $settings is not valid JSON; fix it and re-run" >&2; exit 1; }

# Status line script
if [ -f "$claude_dir/statusline.sh" ] && ! cmp -s "$here/statusline.sh" "$claude_dir/statusline.sh"; then
  cp "$claude_dir/statusline.sh" "$claude_dir/statusline.sh.bak"
  echo "Backed up existing statusline.sh -> statusline.sh.bak"
fi
install -m 755 "$here/statusline.sh" "$claude_dir/statusline.sh"
echo "Installed $claude_dir/statusline.sh"

# Settings: merge recommended keys, keep everything else
tmp=$(mktemp)
trap 'rm -f "$tmp"' EXIT
jq '
  .permissions.defaultMode = "auto"
  | .outputStyle = "Concise"
  | .spinnerTipsEnabled = false
  | .promptSuggestionEnabled = false
  | .promptCacheTtl = "1h"
  | .statusLine = {type: "command", command: "~/.claude/statusline.sh", refreshInterval: 60}
' "$settings" > "$tmp"

if diff -q <(jq -S . "$settings") <(jq -S . "$tmp") >/dev/null; then
  echo "Settings already up to date: $settings"
else
  cp "$settings" "$settings.bak"
  echo "Updated $settings (previous version in settings.json.bak). Changes:"
  diff <(jq -S . "$settings") <(jq -S . "$tmp") || true
  cat "$tmp" > "$settings"
fi

echo "Done. Status line shows after the next message; other settings apply to new sessions."
