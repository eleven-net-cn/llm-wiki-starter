# Detection protocol

## Command presence

Use `command -v <tool>` for CLI tools. Do not use `which` (not POSIX-portable on Windows Git Bash).

- `command -v node` — Node.js
- `command -v git` — Git
- `command -v jq` — jq
- `command -v curl` — curl
- `command -v claude` — Claude Code
- `command -v codex` — Codex CLI
- `command -v gemini` — Gemini CLI
- `command -v opencode` — OpenCode
- `command -v gh` — GitHub CLI (needed for Copilot CLI)
- `gh extension list 2>/dev/null | grep -q gh-copilot` — Copilot CLI (extension, not binary)

If a command is missing, its exit status is non-zero; use this in shell logic:

```bash
if command -v node &>/dev/null; then
  echo "✓ Node.js $(node --version)"
else
  echo "✗ Node.js missing"
fi
```

## Obsidian app

- macOS: `[[ -d "/Applications/Obsidian.app" ]]`
- Linux: `command -v obsidian &>/dev/null`
- Windows: `[[ -d "$LOCALAPPDATA/obsidian" ]]` or `[[ -d "/c/Users/$USER/AppData/Local/obsidian" ]]` or `command -v obsidian`

## Agent Skills (kepano/obsidian-skills)

**Priority order (highest first):** `~/.agents/` before `~/.claude/`.

Installed if ANY of these directories exists:

1. `$HOME/.agents/skills/obsidian-markdown`
2. `$HOME/.agents/skills/obsidian-cli`
3. `$HOME/.claude/skills/obsidian-markdown`
4. `$HOME/.claude/skills/obsidian-cli`

## Agent Skills (axtonliu/visual-skills)

Installed if ANY of these exists:

1. `$HOME/.agents/skills/excalidraw-diagram`
2. `$HOME/.agents/skills/obsidian-canvas-creator`
3. `$HOME/.claude/skills/excalidraw-diagram`
4. `$HOME/.claude/skills/obsidian-canvas-creator`
5. `$HOME/.claude/plugins/marketplaces/axton-obsidian-visual-skills/excalidraw-diagram`

## Web Clipper browser extension

Obsidian Web Clipper Chrome extension ID: `cnjifjpddelmedmihgijeibhnjfabmlc`.

Installed if ANY of:

- macOS: `~/Library/Application Support/Google/Chrome/Default/Extensions/cnjifjpddelmedmihgijeibhnjfabmlc/`
- macOS Edge: `~/Library/Application Support/Microsoft Edge/Default/Extensions/cnjifjpddelmedmihgijeibhnjfabmlc/`
- Linux Chrome: `~/.config/google-chrome/Default/Extensions/cnjifjpddelmedmihgijeibhnjfabmlc/`
- Linux Edge: `~/.config/microsoft-edge/Default/Extensions/cnjifjpddelmedmihgijeibhnjfabmlc/`
- Windows Chrome: `$LOCALAPPDATA/Google/Chrome/User Data/Default/Extensions/cnjifjpddelmedmihgijeibhnjfabmlc/`
- Windows Edge: `$LOCALAPPDATA/Microsoft/Edge/User Data/Default/Extensions/cnjifjpddelmedmihgijeibhnjfabmlc/`
- Firefox (any OS): any `*.xpi` under `~/.mozilla/firefox/*/extensions/` named `*obsidian*web*clipper*` — Firefox does not use fixed IDs

## Obsidian plugin

A plugin is installed if `<wiki>/.obsidian/plugins/<plugin_id>/` exists AND contains `manifest.json` of non-zero size.

## Package manager

On macOS:
- `command -v brew` → have brew.

On Linux:
- `command -v apt-get` / `command -v dnf` / `command -v pacman` — in that order.

On Windows (Git Bash or native cmd):
- `command -v winget` / `command -v choco` / `command -v scoop` — in that order.

If no supported package manager on Linux / Windows, report: "No supported package manager detected — you will install tools manually" and continue with what you can.
