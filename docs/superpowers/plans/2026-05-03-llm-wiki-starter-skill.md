# llm-wiki-starter Skill Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a Skill named `llm-wiki-starter` that guides any AI Agent (Claude Code / Codex / Copilot CLI / Gemini CLI / OpenCode) to scaffold an LLM Wiki knowledge base, alongside the existing `install.sh` one-shot path. Extract the 17-plugin list into a shared `plugin-manifest.json` so both paths stay in sync.

**Architecture:** The Skill lives at `skills/llm-wiki-starter/` with a SKILL.md entrypoint and 8 reference files (one per stage). It works via natural-language triggers ("创建 llm-wiki 知识库" / "create llm wiki") or explicit `/llm-wiki-starter` command. `install.sh` is refactored to read the same `plugin-manifest.json` that the Skill reads, and its Skill detection order is flipped to prefer `~/.agents/` over `~/.claude/`. README.md / README.zh-CN.md gain a "two ways to install" section.

**Tech Stack:** Markdown (SKILL.md + references), JSON (plugin manifest), Bash (install.sh), `jq` for JSON parsing in shell, `npx -y skills add` for Skill installation.

**Spec:** `docs/superpowers/specs/2026-05-03-llm-wiki-starter-skill-design.md`

---

## File Structure

**New files (Skill):**
- `skills/llm-wiki-starter/SKILL.md` — frontmatter + 7-stage SOP entry, global principles
- `skills/llm-wiki-starter/references/01-detect-tools.md` — detection protocol
- `skills/llm-wiki-starter/references/02-install-base.md` — Node / Git / jq / curl per-OS install matrix
- `skills/llm-wiki-starter/references/03-install-ai-agents.md` — 5 AI CLI multi-select install commands
- `skills/llm-wiki-starter/references/04-install-obsidian.md` — Obsidian app + Web Clipper detection
- `skills/llm-wiki-starter/references/05-install-plugins.md` — read manifest + download plugins + Minimal theme
- `skills/llm-wiki-starter/references/06-install-skills.md` — kepano + axtonliu, json-canvas soft-disable
- `skills/llm-wiki-starter/references/07-create-wiki.md` — tarball download + layered copy + placeholder replace
- `skills/llm-wiki-starter/references/08-finalize.md` — community-plugins.json, custom-sort init, git init, summary
- `skills/llm-wiki-starter/assets/plugin-manifest.json` — 17 plugins + Minimal theme as single source of truth

**Modified files:**
- `install.sh:232-244` — Skill detection paths, prefer `~/.agents/` over `~/.claude/`
- `install.sh:893-914` — replace hardcoded `core_plugins` / `ux_plugins` arrays with `jq`-driven read from `skills/llm-wiki-starter/assets/plugin-manifest.json`
- `install.sh:974-1011` — theme install loop also reads manifest (theme block)
- `README.md` line ~13 — add "Option A (Skill) / Option B (bash)" install choice
- `README.zh-CN.md` line ~13 — same in Chinese

**No backwards-compat shim, no migration layer**: `install.sh` gains a hard dependency on `skills/llm-wiki-starter/assets/plugin-manifest.json` existing relative to the script. The tarball download path already fetches the whole repo (`install.sh:758`), so the manifest travels with the repo.

---

## Task 1: Create plugin-manifest.json (single source of truth)

**Why first:** Both Skill and install.sh depend on this file. Committing the manifest before touching either consumer means Task 2+ can reference a concrete path, and Task 11 (install.sh refactor) has a target to read.

**Files:**
- Create: `skills/llm-wiki-starter/assets/plugin-manifest.json`

- [ ] **Step 1: Create the directories and manifest file**

```bash
mkdir -p skills/llm-wiki-starter/assets
```

Write `skills/llm-wiki-starter/assets/plugin-manifest.json`:

```json
{
  "core": [
    {"repo": "YishenTu/claudian", "id": "claudian", "desc": "AI agent in vault (Claude Code/Codex/OpenCode)"},
    {"repo": "blacksmithgu/obsidian-dataview", "id": "dataview", "desc": "Query and display data from notes"},
    {"repo": "SilentVoid13/Templater", "id": "templater-obsidian", "desc": "Templates and automation"},
    {"repo": "Vinzent03/obsidian-git", "id": "obsidian-git", "desc": "Git version control", "requires": "git"},
    {"repo": "platers/obsidian-linter", "id": "obsidian-linter", "desc": "Markdown linting"},
    {"repo": "pjeby/tag-wrangler", "id": "tag-wrangler", "desc": "Tag management"},
    {"repo": "TfTHacker/obsidian42-strange-new-worlds", "id": "obsidian42-strange-new-worlds", "desc": "Link context"},
    {"repo": "mirnovov/obsidian-homepage", "id": "homepage", "desc": "Dashboard/homepage"},
    {"repo": "SebastianMC/obsidian-custom-sort", "id": "custom-sort", "desc": "Custom file sorting"}
  ],
  "ux": [
    {"repo": "scambier/obsidian-omnisearch", "id": "omnisearch", "desc": "Fuzzy search across vault"},
    {"repo": "darlal/obsidian-switcher-plus", "id": "darlal-switcher-plus", "desc": "Quick switcher with headings"},
    {"repo": "kepano/obsidian-minimal-settings", "id": "obsidian-minimal-settings", "desc": "Minimal theme settings"},
    {"repo": "kepano/obsidian-hider", "id": "obsidian-hider", "desc": "Hide UI elements"},
    {"repo": "PKM-er/obsidian-editing-toolbar", "id": "editing-toolbar", "desc": "Word-like toolbar + F11 fullscreen"},
    {"repo": "zsviczian/obsidian-excalidraw-plugin", "id": "obsidian-excalidraw-plugin", "desc": "Hand-drawn diagrams"},
    {"repo": "guopenghui/obsidian-quiet-outline", "id": "obsidian-quiet-outline", "desc": "Enhanced outline"},
    {"repo": "yonatan-reicher/obsidian-open-in-terminal", "id": "open-in-terminal", "desc": "Open vault in terminal"}
  ],
  "theme": {"repo": "kepano/obsidian-minimal", "id": "Minimal"}
}
```

- [ ] **Step 2: Verify JSON validity**

Run: `jq . skills/llm-wiki-starter/assets/plugin-manifest.json`
Expected: pretty-printed JSON, no parse error.

- [ ] **Step 3: Verify the 17 IDs match install.sh current list**

Run:

```bash
diff <(jq -r '.core[].id, .ux[].id' skills/llm-wiki-starter/assets/plugin-manifest.json) \
     <(awk '/^  local core_plugins=\(/,/^  \)/' install.sh | grep -oE '\|[a-z0-9-]+"' | tr -d '"|'; \
       awk '/^  local ux_plugins=\(/,/^  \)/'   install.sh | grep -oE '\|[a-z0-9-]+"' | tr -d '"|')
```

Expected: empty diff (both sides list 9 core + 8 ux = 17 ids in the same order).

- [ ] **Step 4: Commit**

```bash
git add skills/llm-wiki-starter/assets/plugin-manifest.json
git commit -m "feat(skill): add plugin-manifest.json as single source of truth

Extracts the 17 Obsidian plugins + Minimal theme into a shared JSON
that both install.sh and the upcoming llm-wiki-starter Skill will
consume, eliminating duplicate plugin lists."
```

---

## Task 2: Create SKILL.md with frontmatter and workflow entry

**Files:**
- Create: `skills/llm-wiki-starter/SKILL.md`

- [ ] **Step 1: Write SKILL.md**

```markdown
---
name: llm-wiki-starter
description: Scaffold an LLM Wiki knowledge base (Andrej Karpathy pattern) — detect and install base tools, AI agents, Obsidian + 17 plugins + Minimal theme + shortcuts, check for browser Web Clipper, and create the vault from the official template. Use when user says 创建 llm-wiki 知识库, 创建知识库, create llm wiki, scaffold llm wiki, set up knowledge base with Obsidian + AI agent, or invokes /llm-wiki-starter.
---

# llm-wiki-starter

Guide the user through scaffolding an LLM Wiki knowledge base end-to-end: detect what's already installed, install what's missing across OS/package-manager combinations, create the vault from the official template, and configure Obsidian.

## When to use

- Natural language: user says 创建 llm-wiki 知识库, 创建知识库, create llm wiki, scaffold llm wiki, set up knowledge base.
- Explicit command: `/llm-wiki-starter` (optionally with `--name <wiki-name>`, `--lang <en|zh>`, `--dir <path>`, `--skip-tools`, `--only-obsidian`).

If explicit command is used with parameters, skip the matching interactive prompts.

## Global principles (apply to every stage)

1. **Detect before install.** Each step: check if target exists → print ✓ skip / ↓ install / ⚠ fail. Never reinstall.
2. **Failures do not block.** On single-item failure, record it to a "manual install" list and continue. Print the full list at the end.
3. **Respect OS and shell.** Detect with `uname -s` (macOS / Linux / Windows-via-Git-Bash). If running under native Windows cmd/PowerShell (no `uname`), use winget/choco/scoop directly — do not assume bash.
4. **Use the host CLI's native interaction.** If you are Claude Code, use AskUserQuestion. If Codex or another CLI, use its native prompt mechanism. Do not hardcode a UI shape.
5. **Idempotent and re-runnable.** A second run from any point must skip completed items without breaking anything.
6. **Do not prompt for login / API keys / tokens.** After installing an AI CLI, stop. The user configures credentials on their own.
7. **Windows line endings.** When writing files the user will commit, use LF (Unix) line endings.

## Workflow (7 stages)

Execute stages in order. Read the matching reference file before each stage. Do not skip reference files — they contain exact commands.

| # | Stage | Reference |
|---|---|---|
| 0 | Entry alignment (OS detect, plan, confirm) | `SKILL.md` (this file, section below) |
| 1 | Base tools (Node / Git / jq / curl) | `references/02-install-base.md` |
| 2 | AI CLIs (5-way multi-select, default Claude Code) | `references/03-install-ai-agents.md` |
| 3 | Agent Skills (kepano + axtonliu) | `references/06-install-skills.md` |
| 4 | Obsidian app + Web Clipper | `references/04-install-obsidian.md` |
| 5 | Create wiki from template | `references/07-create-wiki.md` |
| 6 | Obsidian plugins + Minimal theme | `references/05-install-plugins.md` |
| 7 | Finalize (git, summary) | `references/08-finalize.md` |

Detection rules shared across stages: see `references/01-detect-tools.md`.

## Stage 0: Entry alignment

1. Run `uname -s` to detect OS. Record as `OS` = macos / linux / windows.
2. Announce the plan in one sentence: "I'll detect what's installed, install missing tools, create your wiki, and configure Obsidian."
3. Unless the user invoked `/llm-wiki-starter` (explicit command = confirmed intent), ask: "Proceed?" Accept yes/proceed/继续/ok as confirmation.
4. Parse any CLI parameters passed with `/llm-wiki-starter`. Remember them for later stages.

Then proceed to stage 1.

## Canvas operations constraint (important)

After Stage 3 installs kepano/obsidian-skills, **5 skills arrive in the bundle, one of which is `json-canvas`**. For this workflow and all Canvas operations in the resulting wiki:

> Use `obsidian-canvas-creator` (from axtonliu/visual-skills) for all Canvas creation and editing. Do NOT use `json-canvas`.

Include this constraint in the final summary (Stage 7) so the user and future AI sessions see it.
```

- [ ] **Step 2: Verify frontmatter parses as valid YAML**

Run:

```bash
python3 -c "import yaml, sys; doc = open('skills/llm-wiki-starter/SKILL.md').read().split('---')[1]; print(yaml.safe_load(doc))"
```

Expected: dict with `name: llm-wiki-starter` and a `description` string.

- [ ] **Step 3: Commit**

```bash
git add skills/llm-wiki-starter/SKILL.md
git commit -m "feat(skill): add SKILL.md with 7-stage workflow entry

Frontmatter defines llm-wiki-starter as auto-triggering on natural
language phrases (创建 llm-wiki 知识库, create llm wiki) or explicit
/llm-wiki-starter command. Body outlines global principles, stage
table, and the json-canvas soft-disable constraint."
```

---

## Task 3: Write references/01-detect-tools.md

**Files:**
- Create: `skills/llm-wiki-starter/references/01-detect-tools.md`

- [ ] **Step 1: Create the file**

```markdown
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
```

- [ ] **Step 2: Commit**

```bash
git add skills/llm-wiki-starter/references/01-detect-tools.md
git commit -m "feat(skill): add detection protocol reference

Documents detection commands for CLIs, Obsidian app, agent skills
(~/.agents preferred over ~/.claude), Web Clipper browser extension
across browsers/OS, Obsidian plugins, and package managers."
```

---

## Task 4: Write references/02-install-base.md

**Files:**
- Create: `skills/llm-wiki-starter/references/02-install-base.md`

- [ ] **Step 1: Create the file**

```markdown
# Stage 1: Install base tools

Install these, in order: curl, Node.js, jq, Git. Skip any that `command -v` already finds.

Report progress per tool. On failure, record to manual-install list and continue.

## curl

Required for tarball download in Stage 5. Almost always pre-installed.

- macOS / Linux: pre-installed; if truly missing, `brew install curl` / `apt-get install -y curl` / `dnf install -y curl` / `pacman -S --noconfirm curl`.
- Windows 10+: pre-installed as `curl.exe`. If missing, `winget install curl.curl`.

## Node.js (LTS)

| OS | Command |
|---|---|
| macOS | `brew install node` |
| Linux (apt) | `sudo apt-get update -qq && sudo apt-get install -y -qq nodejs npm` |
| Linux (dnf) | `sudo dnf install -y -q nodejs npm` |
| Linux (pacman) | `sudo pacman -S --noconfirm nodejs npm` |
| Windows (winget) | `winget install OpenJS.NodeJS.LTS --accept-source-agreements --accept-package-agreements` |
| Windows (choco) | `choco install nodejs-lts -y` |
| Windows (scoop) | `scoop install nodejs-lts` |

Verify: `command -v node && node --version` should report v18+.

Fallback: print `https://nodejs.org` for manual install.

## jq

Used by `install.sh` to parse plugin-manifest.json. The Skill itself does not need jq (Agent can read JSON natively).

| OS | Command |
|---|---|
| macOS | `brew install jq` |
| Linux (apt) | `sudo apt-get install -y -qq jq` |
| Linux (dnf) | `sudo dnf install -y -q jq` |
| Linux (pacman) | `sudo pacman -S --noconfirm jq` |
| Windows (winget) | `winget install jqlang.jq --accept-source-agreements --accept-package-agreements` |
| Windows (choco) | `choco install jq -y` |
| Windows (scoop) | `scoop install jq` |

## Git

| OS | Command |
|---|---|
| macOS | `brew install git` (fallback: `xcode-select --install`) |
| Linux (apt) | `sudo apt-get install -y -qq git` |
| Linux (dnf) | `sudo dnf install -y -q git` |
| Linux (pacman) | `sudo pacman -S --noconfirm git` |
| Windows | `winget install Git.Git --accept-source-agreements --accept-package-agreements` |

If Git install fails, Stage 7 will skip `git init` but the wiki is still usable.

## Homebrew (macOS only)

If on macOS and `brew` is missing, before any brew commands:

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
eval "$(/opt/homebrew/bin/brew shellenv 2>/dev/null || /usr/local/bin/brew shellenv 2>/dev/null)"
```

Tell the user this will prompt for sudo and take ~5 minutes.

## Verification checkpoint

After this stage, verify:

```bash
command -v curl && command -v node && command -v jq && command -v git
```

All four should be present. Missing ones are in the manual-install list; print them and proceed to Stage 2.
```

- [ ] **Step 2: Commit**

```bash
git add skills/llm-wiki-starter/references/02-install-base.md
git commit -m "feat(skill): add base tool install matrix

Covers curl, Node.js LTS, jq, Git across macOS (brew + xcode-select),
Linux (apt/dnf/pacman), and Windows (winget/choco/scoop). Homebrew
auto-install hint for fresh macOS."
```

---

## Task 5: Write references/03-install-ai-agents.md

**Files:**
- Create: `skills/llm-wiki-starter/references/03-install-ai-agents.md`

- [ ] **Step 1: Create the file**

```markdown
# Stage 2: Install AI CLIs

Present 5 options as multi-select. Pre-check Claude Code (default).

Do NOT prompt for login, API keys, or any post-install configuration. After each install succeeds, move on.

## The 5 options

| # | CLI | Default? | Detect | Install |
|---|---|---|---|---|
| 1 | **Claude Code** | ✓ | `command -v claude` | `npm install -g @anthropic-ai/claude-code` |
| 2 | **Codex CLI** |   | `command -v codex` | `npm install -g @openai/codex` |
| 3 | **GitHub Copilot CLI** |   | `gh extension list \| grep -q gh-copilot` | `gh extension install github/gh-copilot` (requires `gh`) |
| 4 | **Gemini CLI** |   | `command -v gemini` | `npm install -g @google/gemini-cli` |
| 5 | **OpenCode** |   | `command -v opencode` | `curl -fsSL https://opencode.ai/install \| bash` |

Note: exact npm package names may evolve. If the install command above reports "package not found", ask the user to confirm the current package name or skip this tool.

## Multi-select interaction

Using your host CLI's native mechanism (e.g. AskUserQuestion for Claude Code):

- Question: "Which AI CLIs to install? (multi-select, Claude Code pre-checked)"
- Options: five rows above
- Let user confirm / modify / proceed.

## GitHub CLI (`gh`) prerequisite for Copilot

Copilot CLI is a `gh` extension, not a standalone binary. If user picks Copilot and `gh` is missing, install `gh` first:

| OS | Command |
|---|---|
| macOS | `brew install gh` |
| Linux (apt) | `sudo apt-get install -y gh` (may need `apt-key` setup first — see cli.github.com/manual/installation) |
| Linux (dnf) | `sudo dnf install -y gh` |
| Windows | `winget install GitHub.cli` |

After `gh` is present, also tell the user: "Run `gh auth login` later to use Copilot CLI" — this is informational only; do not invoke it in this Skill.

## Handling failures

If one CLI's install fails (network, registry, whatever): record to manual-install list, continue with the next selected CLI. Do not abort the whole stage.

## Post-stage

After attempting all selected CLIs, print summary:

```
AI CLIs:
  ✓ Claude Code (version)
  ✓ Codex CLI
  ⚠ Gemini CLI — install failed, run: npm install -g @google/gemini-cli
```

Then proceed to Stage 3.
```

- [ ] **Step 2: Commit**

```bash
git add skills/llm-wiki-starter/references/03-install-ai-agents.md
git commit -m "feat(skill): add AI CLI multi-select install matrix

5 CLIs with Claude Code default-selected, per-OS install commands,
gh prerequisite handling for Copilot, and explicit 'no login prompts'
directive. Failures recorded to manual-install list."
```

---

## Task 6: Write references/04-install-obsidian.md

**Files:**
- Create: `skills/llm-wiki-starter/references/04-install-obsidian.md`

- [ ] **Step 1: Create the file**

```markdown
# Stage 4: Install Obsidian app + Web Clipper

## Obsidian app

Check detection per `references/01-detect-tools.md`. If installed, ✓ and move on.

| OS | Command (fallback chain) |
|---|---|
| macOS | `brew install --cask obsidian` (fallback: official installer from obsidian.md/download) |
| Linux | `sudo snap install obsidian --classic` → `flatpak install -y flathub md.obsidian.Obsidian` (fallback: AppImage from obsidian.md) |
| Windows (winget) | `winget install Obsidian.Obsidian --accept-source-agreements --accept-package-agreements` |
| Windows (choco) | `choco install obsidian -y` |
| Windows (scoop) | `scoop install obsidian` |

On install failure, record to manual list: `Obsidian: https://obsidian.md/download`.

## Web Clipper (browser extension)

**Cannot be installed via CLI** — browser extensions require user approval in-browser. Strategy:

1. Detect (per `references/01-detect-tools.md`). If any browser's extension folder contains the Obsidian Web Clipper ID, print ✓ and skip.
2. If not detected, print:

```
⚠ Web Clipper (browser extension) — install manually:
    https://obsidian.md/clip
```

3. Do not prompt the user to install it right now; continue to Stage 5. Stage 7 summary will remind them.
```

- [ ] **Step 2: Commit**

```bash
git add skills/llm-wiki-starter/references/04-install-obsidian.md
git commit -m "feat(skill): add Obsidian app + Web Clipper stage

Per-OS install chains (brew, snap/flatpak/AppImage, winget/choco/scoop).
Web Clipper cannot be CLI-installed; detect across browsers and print
obsidian.md/clip link if missing, without blocking the workflow."
```

---

## Task 7: Write references/05-install-plugins.md

**Files:**
- Create: `skills/llm-wiki-starter/references/05-install-plugins.md`

- [ ] **Step 1: Create the file**

```markdown
# Stage 6: Install Obsidian plugins + Minimal theme

Read `skills/llm-wiki-starter/assets/plugin-manifest.json`. It defines:

- `core[]` — 9 plugins (llm-wiki functionality)
- `ux[]` — 8 plugins (editing experience)
- `theme` — Minimal theme

## Plugin download

For each entry `{repo, id, desc, requires?}`:

1. **Skip conditions:**
   - If `<wiki>/.obsidian/plugins/<id>/manifest.json` already exists and is non-empty: print `✓ <id> (exists)` and skip.
   - If `requires: "git"` and Git was not installed successfully: print `- <id> (skipped: no git)` and skip. This applies to `obsidian-git`.

2. **Download three files** from `https://github.com/<repo>/releases/latest/download/`:
   - `main.js` (required)
   - `manifest.json` (required)
   - `styles.css` (optional)

Use curl with 30-second timeout:

```bash
curl -fsSL --max-time 30 "$base_url/main.js" -o "$plugin_dir/main.js"
curl -fsSL --max-time 30 "$base_url/manifest.json" -o "$plugin_dir/manifest.json"
```

3. **styles.css handling** (optional):

```bash
css_status=$(curl -sSL --max-time 30 -w '%{http_code}' -o "$plugin_dir/styles.css" "$base_url/styles.css" 2>/dev/null || echo "000")
if [[ "$css_status" != "200" ]]; then
  rm -f "$plugin_dir/styles.css"
fi
```

Log based on status:
- 200 → keep silently
- 404 → silent (plugin has no CSS)
- anything else (timeout / 5xx) → `⚠ <id>: styles.css not downloaded (HTTP <status>)`

4. **Record installed** id to a list.

## Plugin-specific config

After all plugins installed, for `custom-sort` specifically:

If `<wiki>/.obsidian/plugins/custom-sort/` exists but lacks `data.json`, create it:

```json
{"suspended":false,"statusBarEntryEnabled":true,"notificationsEnabled":true,"customSortContextSubmenu":true}
```

## Theme: Minimal

From `plugin-manifest.json`, `theme.repo` = `kepano/obsidian-minimal`, `theme.id` = `Minimal`.

If `<wiki>/.obsidian/themes/Minimal/` does not exist:

```bash
theme_dir="<wiki>/.obsidian/themes/Minimal"
mkdir -p "$theme_dir"
curl -fsSL --max-time 30 "https://github.com/kepano/obsidian-minimal/releases/latest/download/manifest.json" -o "$theme_dir/manifest.json"
curl -fsSL --max-time 30 "https://github.com/kepano/obsidian-minimal/releases/latest/download/theme.css" -o "$theme_dir/theme.css"
```

## Write community-plugins.json

After all plugins installed, write `<wiki>/.obsidian/community-plugins.json`:

```json
["claudian", "dataview", "templater-obsidian", ...]
```

— an array of all successfully installed plugin ids, in the order they were installed.

## Write appearance.json

If `<wiki>/.obsidian/appearance.json` does not exist, create it:

```json
{"cssTheme": "Minimal"}
```

If it exists, merge `cssTheme: Minimal` into it (do not overwrite unrelated keys).
```

- [ ] **Step 2: Commit**

```bash
git add skills/llm-wiki-starter/references/05-install-plugins.md
git commit -m "feat(skill): add plugin + theme install reference

Reads plugin-manifest.json; downloads main.js/manifest.json plus
optional styles.css (HTTP status 200/404/other discrimination);
initializes custom-sort data.json; installs Minimal theme; writes
community-plugins.json and appearance.json."
```

---

## Task 8: Write references/06-install-skills.md

**Files:**
- Create: `skills/llm-wiki-starter/references/06-install-skills.md`

- [ ] **Step 1: Create the file**

```markdown
# Stage 3: Install Agent Skills

Two packages to install. Both use the vercel-labs/skills CLI via `npx` (no global skills CLI install needed).

## kepano/obsidian-skills

**Install:**

```bash
npx -y skills add kepano/obsidian-skills -g -y
```

**Detect before / verify after** (per `references/01-detect-tools.md` — `~/.agents/` preferred over `~/.claude/`):

```bash
for d in \
  "$HOME/.agents/skills/obsidian-markdown" \
  "$HOME/.agents/skills/obsidian-cli" \
  "$HOME/.claude/skills/obsidian-markdown" \
  "$HOME/.claude/skills/obsidian-cli"; do
  [[ -d "$d" ]] && { echo "✓ kepano/obsidian-skills (found at $d)"; installed=true; break; }
done
```

## axtonliu/axton-obsidian-visual-skills

**Install:**

```bash
npx -y skills add axtonliu/axton-obsidian-visual-skills -g -y
```

**Detect:**

```bash
for d in \
  "$HOME/.agents/skills/excalidraw-diagram" \
  "$HOME/.agents/skills/obsidian-canvas-creator" \
  "$HOME/.claude/skills/excalidraw-diagram" \
  "$HOME/.claude/skills/obsidian-canvas-creator" \
  "$HOME/.claude/plugins/marketplaces/axton-obsidian-visual-skills/excalidraw-diagram"; do
  [[ -d "$d" ]] && { echo "✓ axtonliu/visual-skills (found at $d)"; installed=true; break; }
done
```

## Canvas operations constraint (MUST tell the user)

`kepano/obsidian-skills` bundles 5 skills: `defuddle`, `json-canvas`, `obsidian-bases`, `obsidian-cli`, `obsidian-markdown`.

**json-canvas is installed but should not be used.** All Canvas creation and editing must use `obsidian-canvas-creator` (from axtonliu/visual-skills).

Do not delete the `json-canvas` directory — `skills update` may pull it back. Instead, the Stage 7 summary and the generated wiki's CLAUDE.md / AGENTS.md (already present in the template) should note this constraint.

## Failure handling

If either `npx` install fails (network, registry):

- Record to manual-install list:
  - `kepano/obsidian-skills: npx -y skills add kepano/obsidian-skills -g -y`
  - `axtonliu/visual-skills: npx -y skills add axtonliu/axton-obsidian-visual-skills -g -y`
- Continue to Stage 4; skills are not critical-path for creating the wiki.
```

- [ ] **Step 2: Commit**

```bash
git add skills/llm-wiki-starter/references/06-install-skills.md
git commit -m "feat(skill): add agent-skills install reference

Installs kepano/obsidian-skills + axtonliu/visual-skills via npx.
Detection prefers ~/.agents/ over ~/.claude/. Documents json-canvas
soft-disable constraint (installed but not to be used; Canvas work
goes through obsidian-canvas-creator)."
```

---

## Task 9: Write references/07-create-wiki.md

**Files:**
- Create: `skills/llm-wiki-starter/references/07-create-wiki.md`

- [ ] **Step 1: Create the file**

```markdown
# Stage 5: Create wiki from template

## Gather inputs

Using host CLI native prompts (skip any already provided via `/llm-wiki-starter` parameters):

1. **Wiki name** (default `my-wiki`) — used for directory name and placeholder replacement.
2. **Language** (`en` | `zh`, default `en`) — picks template overlay.
3. **Parent directory** (default `$(pwd)`) — wiki will be created at `<parent>/<name>`.

Validate:

- If `<parent>/<name>` exists:
  - If it contains `CLAUDE.md`: treat as existing wiki, skip creation and proceed to Stage 6 (configure Obsidian in place).
  - Otherwise: ask user for a different name.

## Download template tarball

```bash
TMPDIR=$(mktemp -d)
trap "rm -rf $TMPDIR" EXIT

curl -fsSL https://github.com/eleven-net-cn/llm-wiki-starter/archive/refs/heads/main.tar.gz \
  -o "$TMPDIR/repo.tar.gz"

tar -xzf "$TMPDIR/repo.tar.gz" -C "$TMPDIR"

TEMPLATE_ROOT=$(find "$TMPDIR" -maxdepth 1 -type d -name 'llm-wiki-starter-*' | head -1)/template
```

Verify `TEMPLATE_ROOT/base` and `TEMPLATE_ROOT/<lang>` directories exist.

## Layered copy

```bash
WIKI_DIR="<parent>/<name>"
mkdir -p "$WIKI_DIR"

# Layer 1: shared base (.gitignore, canvas/, root sortspec)
cp -a "$TEMPLATE_ROOT/base/." "$WIKI_DIR/"

# Layer 2: language overlay (CLAUDE.md, AGENTS.md, README.md, raw/, wiki/)
cp -a "$TEMPLATE_ROOT/$LANG/." "$WIKI_DIR/"
```

Create empty directories git does not track. For `lang=zh`:

```bash
mkdir -p "$WIKI_DIR"/{wiki/assets/excalidraw,canvas,raw/收件箱,raw/assets,wiki/概念,wiki/资料摘要,wiki/综合分析,wiki/归档}
```

For `lang=en`:

```bash
mkdir -p "$WIKI_DIR"/{wiki/assets/excalidraw,canvas,raw/inbox,raw/assets,wiki/concepts,wiki/summaries,wiki/synthesis,wiki/archived}
```

## Placeholder replacement

Replace `<Wiki Name>`, `<wiki-name>`, and `{{date}}` in known files.

Files to patch (exist only in some languages — check each):

- `CLAUDE.md`, `AGENTS.md`, `README.md`
- `wiki/知识库概览.md`, `wiki/Wiki 目录.md`, `wiki/操作日志.md` (zh)
- `wiki/Overview.md`, `wiki/Index.md`, `wiki/Changelog.md` (en)

On macOS / Linux (GNU sed or BSD sed):

```bash
TODAY=$(date +%Y-%m-%d)
for f in "${FILES[@]}"; do
  [[ -f "$WIKI_DIR/$f" ]] || continue
  if [[ "$OS" == "macos" ]]; then
    sed -i '' "s/<Wiki Name>/$NAME/g; s/<wiki-name>/$NAME/g; s/{{date}}/$TODAY/g" "$WIKI_DIR/$f"
  else
    sed -i "s/<Wiki Name>/$NAME/g; s/<wiki-name>/$NAME/g; s/{{date}}/$TODAY/g" "$WIKI_DIR/$f"
  fi
done
```

On Windows native (cmd / PowerShell without sed), use PowerShell:

```powershell
$today = Get-Date -Format "yyyy-MM-dd"
foreach ($f in $files) {
  if (Test-Path "$wikiDir\$f") {
    (Get-Content "$wikiDir\$f") `
      -replace '<Wiki Name>', $name `
      -replace '<wiki-name>', $name `
      -replace '\{\{date\}\}', $today |
    Set-Content -Encoding UTF8 "$wikiDir\$f"
  }
}
```

## Verify

After Stage 5:

- `$WIKI_DIR/CLAUDE.md` exists and contains `$NAME` (not `<Wiki Name>`)
- `$WIKI_DIR/.gitignore` exists (from base layer)
- `$WIKI_DIR/raw/` and `$WIKI_DIR/wiki/` directories populated

Proceed to Stage 6.
```

- [ ] **Step 2: Commit**

```bash
git add skills/llm-wiki-starter/references/07-create-wiki.md
git commit -m "feat(skill): add wiki creation from tarball reference

Downloads repo tarball, extracts template/{base,<lang>}, layers them
into target dir, creates untracked dirs, replaces <Wiki Name> /
<wiki-name> / {{date}} placeholders. Provides both sed (macOS/Linux)
and PowerShell (Windows native) code paths."
```

---

## Task 10: Write references/08-finalize.md

**Files:**
- Create: `skills/llm-wiki-starter/references/08-finalize.md`

- [ ] **Step 1: Create the file**

```markdown
# Stage 7: Finalize

## Git initialization

If Git was successfully installed (Stage 1) and the wiki directory does not already have `.git/`:

```bash
cd "$WIKI_DIR"
git init -q
git add .
git -c user.email=you@example.com -c user.name="Wiki User" commit -q -m "Initial wiki scaffold"
cd -
```

If Git is missing, skip this block; the wiki is still usable.

## Summary output

Print a structured summary to stdout. Scale to the user's actual install results.

```
✓ Wiki created: <WIKI_DIR> (lang: <LANG>)

Installed this run:
  ✓ Claude Code (<version>)
  ✓ Node.js (<version>)
  ✓ Obsidian
  ✓ kepano/obsidian-skills
    ⚠ Canvas operations must use obsidian-canvas-creator (not json-canvas)
  ✓ axtonliu/visual-skills
  ✓ 17 Obsidian plugins + Minimal theme

Skipped (already installed):
  - Git (<version>)

Manual install required:
  ⚠ Web Clipper: https://obsidian.md/clip (install in your browser)
  ⚠ Codex CLI: npm install -g @openai/codex (network failed)

Quick start:
  1. cd <WIKI_DIR>
  2. Open as Obsidian vault:
       macOS:   open -a Obsidian .
       Linux:   obsidian .
       Windows: start obsidian .
  3. Start your AI agent:
       claude                 (Claude Code)
       codex                  (Codex CLI)
       gh copilot             (Copilot CLI)
       gemini                 (Gemini CLI)
       opencode               (OpenCode)
```

Replace bracketed placeholders with actual values. Include only the AI CLIs the user installed.

## Re-triggering

Tell the user: "You can re-run this workflow anytime with `/llm-wiki-starter` — I'll skip everything already installed."
```

- [ ] **Step 2: Commit**

```bash
git add skills/llm-wiki-starter/references/08-finalize.md
git commit -m "feat(skill): add finalize stage reference

Runs git init for the fresh wiki (if git available), prints structured
summary (installed / skipped / manual-install), lists quick-start
commands for each AI CLI the user installed, reminds user the workflow
is re-runnable."
```

---

## Task 11: Refactor install.sh — read plugin manifest, flip skill detection order

**Files:**
- Modify: `install.sh:232-244` (skill detection path order)
- Modify: `install.sh:893-914` (core_plugins / ux_plugins arrays → jq read)
- Modify: `install.sh:974-1011` (theme — read from manifest)

- [ ] **Step 1: Read current skill detection block to confirm line numbers**

Run:

```bash
sed -n '230,248p' install.sh
```

Expected: the `# Claude Code Skills — check ~/.claude/skills/...` block with `skills_dir` listed before `agents_dir` in the `-d` chain.

- [ ] **Step 2: Flip the skill detection order to prefer ~/.agents/**

Replace the block (current lines 232-245 in install.sh):

```bash
  # Claude Code Skills — check ~/.agents/skills/ (preferred), ~/.claude/skills/, and plugins/marketplaces/
  local agents_dir="$HOME/.agents/skills"
  local skills_dir="$HOME/.claude/skills"
  local plugins_dir="$HOME/.claude/plugins/marketplaces"

  if [[ -d "$agents_dir/obsidian-markdown" || -d "$agents_dir/obsidian-cli" || \
        -d "$skills_dir/obsidian-markdown" || -d "$skills_dir/obsidian-cli" ]]; then
    HAS_OBSIDIAN_SKILLS=true
  fi
  if [[ -d "$agents_dir/excalidraw-diagram" || -d "$agents_dir/obsidian-canvas-creator" || \
        -d "$skills_dir/excalidraw-diagram" || -d "$skills_dir/obsidian-canvas-creator" || \
        -d "$plugins_dir/axton-obsidian-visual-skills/excalidraw-diagram" ]]; then
    HAS_VISUAL_SKILLS=true
  fi
```

Also scan `install_skills()` (around line 657) for the post-install verification block that lists `~/.claude/skills/` first. Flip that too:

Find:

```bash
if [[ -d "$HOME/.claude/skills/obsidian-markdown" ]] || \
   [[ -d "$HOME/.claude/skills/obsidian-cli" ]] || \
   [[ -d "$HOME/.agents/skills/obsidian-markdown" ]]; then
```

Replace with:

```bash
if [[ -d "$HOME/.agents/skills/obsidian-markdown" ]] || \
   [[ -d "$HOME/.agents/skills/obsidian-cli" ]] || \
   [[ -d "$HOME/.claude/skills/obsidian-markdown" ]] || \
   [[ -d "$HOME/.claude/skills/obsidian-cli" ]]; then
```

Do the same for the visual-skills verification block if it has a similar order.

- [ ] **Step 3: Verify bash syntax**

```bash
bash -n install.sh
```

Expected: no output (syntax OK).

- [ ] **Step 4: Add a helper to read plugin-manifest.json**

Immediately before `install_obsidian_plugins()` (currently around line 880), insert a new helper:

```bash
# Reads plugin entries from the manifest. Args: group = "core" | "ux".
# Echoes one "repo|id" per line.
read_plugin_manifest() {
  local group="$1"
  local manifest
  # Locate manifest relative to install.sh script dir, or inside extracted template tmpdir.
  local script_dir
  script_dir="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" 2>/dev/null && pwd)" || return 1
  if [[ -f "$script_dir/skills/llm-wiki-starter/assets/plugin-manifest.json" ]]; then
    manifest="$script_dir/skills/llm-wiki-starter/assets/plugin-manifest.json"
  elif [[ -n "$TEMPLATE_TMPDIR" && -f "$TEMPLATE_TMPDIR/repo/skills/llm-wiki-starter/assets/plugin-manifest.json" ]]; then
    manifest="$TEMPLATE_TMPDIR/repo/skills/llm-wiki-starter/assets/plugin-manifest.json"
  elif [[ -n "$LOCAL_TEMPLATE" && -f "$(dirname "$LOCAL_TEMPLATE")/skills/llm-wiki-starter/assets/plugin-manifest.json" ]]; then
    manifest="$(dirname "$LOCAL_TEMPLATE")/skills/llm-wiki-starter/assets/plugin-manifest.json"
  else
    fail "plugin-manifest.json not found — expected at skills/llm-wiki-starter/assets/"
  fi

  if command -v jq &>/dev/null; then
    jq -r --arg g "$group" '.[$g][] | "\(.repo)|\(.id)"' "$manifest"
  else
    python3 -c "
import json, sys
with open('$manifest') as f:
    d = json.load(f)
for p in d['$group']:
    print(p['repo'] + '|' + p['id'])
"
  fi
}

# Reads theme entry. Echoes "repo|id".
read_theme_manifest() {
  local manifest
  local script_dir
  script_dir="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" 2>/dev/null && pwd)" || return 1
  if [[ -f "$script_dir/skills/llm-wiki-starter/assets/plugin-manifest.json" ]]; then
    manifest="$script_dir/skills/llm-wiki-starter/assets/plugin-manifest.json"
  elif [[ -n "$TEMPLATE_TMPDIR" && -f "$TEMPLATE_TMPDIR/repo/skills/llm-wiki-starter/assets/plugin-manifest.json" ]]; then
    manifest="$TEMPLATE_TMPDIR/repo/skills/llm-wiki-starter/assets/plugin-manifest.json"
  elif [[ -n "$LOCAL_TEMPLATE" && -f "$(dirname "$LOCAL_TEMPLATE")/skills/llm-wiki-starter/assets/plugin-manifest.json" ]]; then
    manifest="$(dirname "$LOCAL_TEMPLATE")/skills/llm-wiki-starter/assets/plugin-manifest.json"
  else
    fail "plugin-manifest.json not found"
  fi

  if command -v jq &>/dev/null; then
    jq -r '.theme | "\(.repo)|\(.id)"' "$manifest"
  else
    python3 -c "
import json
with open('$manifest') as f:
    d = json.load(f)
print(d['theme']['repo'] + '|' + d['theme']['id'])
"
  fi
}
```

- [ ] **Step 5: Replace hardcoded plugin arrays with manifest reads**

In `install_obsidian_plugins()` (currently around line 893), replace:

```bash
  local core_plugins=(
    "YishenTu/claudian|claudian"                           # AI agent in vault (Claude Code/Codex/OpenCode)
    "blacksmithgu/obsidian-dataview|dataview"              # Query and display data from notes
    ...9 entries...
  )

  local ux_plugins=(
    "scambier/obsidian-omnisearch|omnisearch"              # Fuzzy search across vault
    ...8 entries...
  )
```

with:

```bash
  local core_plugins=()
  while IFS= read -r line; do
    [[ -n "$line" ]] && core_plugins+=("$line")
  done < <(read_plugin_manifest core)

  local ux_plugins=()
  while IFS= read -r line; do
    [[ -n "$line" ]] && ux_plugins+=("$line")
  done < <(read_plugin_manifest ux)

  if [[ ${#core_plugins[@]} -eq 0 || ${#ux_plugins[@]} -eq 0 ]]; then
    fail "Plugin manifest empty or unreadable at skills/llm-wiki-starter/assets/plugin-manifest.json"
  fi
```

- [ ] **Step 6: Update theme install to use manifest**

In the theme block (currently around line 976), replace the hardcoded:

```bash
  local theme_dir="$wiki_dir/.obsidian/themes/Minimal"
  local theme_url="https://github.com/kepano/obsidian-minimal/releases/latest/download"
```

with:

```bash
  local theme_entry
  theme_entry=$(read_theme_manifest)
  local theme_repo="${theme_entry%%|*}"
  local theme_id="${theme_entry##*|}"
  local theme_dir="$wiki_dir/.obsidian/themes/$theme_id"
  local theme_url="https://github.com/$theme_repo/releases/latest/download"
```

- [ ] **Step 7: Verify bash syntax and smoke-test**

Run:

```bash
bash -n install.sh
```

Expected: no output.

Then run a dry-check: read the manifest paths the helper would find and count entries.

```bash
source <(sed -n '/^read_plugin_manifest/,/^}/p' install.sh)
read_plugin_manifest core | wc -l   # expect 9
read_plugin_manifest ux   | wc -l   # expect 8
```

If mismatch, inspect manifest. Fix before commit.

- [ ] **Step 8: Commit**

```bash
git add install.sh
git commit -m "refactor: read plugin manifest from shared JSON source

Replaces hardcoded core_plugins / ux_plugins / theme values in
install.sh with reads from skills/llm-wiki-starter/assets/plugin-manifest.json
via jq (or python3 fallback). Shared source with the upcoming Skill
prevents two places drifting out of sync.

Also flips Agent Skills detection order to prefer ~/.agents/
(~/.claude/ comes second), both in detect_installed() and in the
install_skills() post-install verification block."
```

---

## Task 12: Update README.md — add two install options

**Files:**
- Modify: `README.md` lines ~13-19

- [ ] **Step 1: Read current `## Installation` block**

Run:

```bash
sed -n '13,25p' README.md
```

Observe current structure.

- [ ] **Step 2: Rewrite Installation section**

Replace:

```markdown
## Installation

```bash
curl -fsSL https://raw.githubusercontent.com/eleven-net-cn/llm-wiki-starter/main/install.sh | bash
```
![create-ai-wiki](./assets/create-ai-wiki.svg)

> **Windows users**: Run the installer from **Git Bash** (recommended) or **WSL2** — ...
```

with (keeping the Windows note with its associated option):

```markdown
## Installation

Pick one of two paths:

### Option A — Skill-based (recommended for AI Agent users)

Install the Skill once, then any AI CLI (Claude Code / Codex / Copilot CLI / Gemini CLI / OpenCode) can scaffold the wiki for you:

```bash
npx -y skills add eleven-net-cn/llm-wiki-starter -g -y
```

Then in your AI CLI say **"create llm wiki"** (中文："创建 llm-wiki 知识库"), or run `/llm-wiki-starter`.

The Agent will detect what's already installed, ask you to pick which AI CLIs you want, and guide you through the full setup — with the freedom to adapt to any OS or package manager.

### Option B — One-shot bash script

```bash
curl -fsSL https://raw.githubusercontent.com/eleven-net-cn/llm-wiki-starter/main/install.sh | bash
```
![create-ai-wiki](./assets/create-ai-wiki.svg)

> **Windows users**: Run the installer from **Git Bash** (recommended) or **WSL2** — `cmd.exe` and PowerShell cannot execute bash scripts. Install [Git for Windows](https://git-scm.com/download/win) (provides Git Bash + curl), then run `git config --global core.autocrlf input` to avoid `bad interpreter` errors. The installer auto-detects winget / Chocolatey / Scoop to fetch Obsidian, Node.js and Git.
```

- [ ] **Step 3: Preview in rendered markdown (optional mental check)**

Visually confirm option A precedes option B and the Windows note is scoped under option B.

- [ ] **Step 4: Commit**

```bash
git add README.md
git commit -m "docs: add Option A (Skill) / Option B (bash) install choice

Leads with the Skill-based path for AI Agent users (one npx command,
then natural-language trigger). The existing curl | bash path stays
as Option B, with the Windows prerequisite note scoped to it since
it only applies to bash."
```

---

## Task 13: Update README.zh-CN.md — same two-option structure in Chinese

**Files:**
- Modify: `README.zh-CN.md` lines ~13-20

- [ ] **Step 1: Read current block**

```bash
sed -n '13,25p' README.zh-CN.md
```

- [ ] **Step 2: Rewrite**

Replace the `## 安装` section with:

```markdown
## 安装

任选一种方式：

### 方式 A — Skill 安装（推荐，面向 AI Agent 用户）

一条命令装好本 Skill，任何 AI CLI（Claude Code / Codex / Copilot CLI / Gemini CLI / OpenCode）都能帮你搭建知识库：

```bash
npx -y skills add eleven-net-cn/llm-wiki-starter -g -y
```

然后在你的 AI CLI 里说 **"创建 llm-wiki 知识库"**（English: "create llm wiki"），或直接运行 `/llm-wiki-starter`。

Agent 会自动检测已装工具、问你选哪些 AI CLI、一步步引导你完成搭建 —— 不受操作系统和包管理器的限制。

### 方式 B — 一键 bash 脚本

```bash
curl -fsSL https://raw.githubusercontent.com/eleven-net-cn/llm-wiki-starter/main/install.sh | bash
```
![create-ai-wiki](./assets/create-ai-wiki.svg)

> **Windows 用户**：安装脚本是 bash 脚本，请在 **Git Bash**（推荐）或 **WSL2** 中执行 —— `cmd.exe` 与 PowerShell 无法运行 bash。先安装 [Git for Windows](https://git-scm.com/download/win)（自带 Git Bash + curl），再执行 `git config --global core.autocrlf input` 避免 `bad interpreter` 错误。脚本会自动检测 winget / Chocolatey / Scoop 来安装 Obsidian、Node.js、Git。
```

- [ ] **Step 3: Commit**

```bash
git add README.zh-CN.md
git commit -m "docs(zh): add Option A (Skill) / Option B (bash) install choice"
```

---

## Task 14: skills CLI compatibility verification (gated manual verification)

**Files:** none (verification step, may lead to Task 15 if it fails)

- [ ] **Step 1: Attempt install via vercel-labs/skills CLI**

Run (in a scratch directory):

```bash
cd /tmp && rm -rf skill-verify && mkdir skill-verify && cd skill-verify
HOME="$(pwd)/fakehome" npx -y skills add eleven-net-cn/llm-wiki-starter -g -y 2>&1 | tee install-log.txt
```

- [ ] **Step 2: Verify the skill was discovered**

Check:

```bash
ls -la fakehome/.claude/skills/ fakehome/.agents/skills/ 2>/dev/null
find fakehome -name SKILL.md 2>/dev/null
```

Expected: a file at `fakehome/.claude/skills/llm-wiki-starter/SKILL.md` or `fakehome/.agents/skills/llm-wiki-starter/SKILL.md`.

- [ ] **Step 3: Decide based on result**

**If found** → skip Task 15, proceed to Task 16.

**If not found (CLI did not discover the skill inside `skills/` parent dir)** → execute Task 15 (fallback layout).

Record the result (with the log) in a commit message comment for the PR so reviewers see which branch was taken.

---

## Task 15: (Conditional) Fallback layout if skills CLI cannot find nested dir

Execute ONLY if Task 14 Step 2 failed.

**Files:**
- Move: `skills/llm-wiki-starter/` → `llm-wiki-starter/` (repo root)
- Modify: `install.sh` — update manifest path in `read_plugin_manifest` / `read_theme_manifest`

- [ ] **Step 1: Move the Skill to repo root**

```bash
git mv skills/llm-wiki-starter llm-wiki-starter
rmdir skills 2>/dev/null || true
```

- [ ] **Step 2: Update install.sh manifest paths**

Find `skills/llm-wiki-starter/assets/plugin-manifest.json` references in `install.sh` (4 places total in the helpers added by Task 11) and replace with `llm-wiki-starter/assets/plugin-manifest.json`.

Run:

```bash
sed -i.bak 's|skills/llm-wiki-starter/assets|llm-wiki-starter/assets|g' install.sh
rm install.sh.bak
grep -n 'llm-wiki-starter/assets' install.sh
```

Expected: 4 matches pointing to `llm-wiki-starter/assets/plugin-manifest.json`.

- [ ] **Step 3: Verify bash syntax and retry skills CLI install**

```bash
bash -n install.sh
cd /tmp && rm -rf skill-verify2 && mkdir skill-verify2 && cd skill-verify2
HOME="$(pwd)/fakehome" npx -y skills add eleven-net-cn/llm-wiki-starter -g -y
find fakehome -name SKILL.md 2>/dev/null
```

Expected: SKILL.md found now.

- [ ] **Step 4: Commit**

```bash
git add .
git commit -m "fix(skill): move to repo root to match skills CLI discovery

vercel-labs/skills CLI does not scan nested skills/<name>/ layout;
moved to repo root llm-wiki-starter/ per the project's convention
(same as kepano/obsidian-skills). install.sh manifest paths updated
to the new location."
```

---

## Task 16: End-to-end verification — Skill auto-trigger + install.sh manifest read

**Files:** none (verification)

- [ ] **Step 1: Install the Skill locally (via file path for testing, NOT GitHub)**

Using whichever layout survived Task 14/15:

```bash
# From the repo root:
skill_src="$(pwd)/skills/llm-wiki-starter"   # or llm-wiki-starter if Task 15 ran
target="$HOME/.claude/skills/llm-wiki-starter"
rm -rf "$target"
cp -a "$skill_src" "$target"
```

- [ ] **Step 2: Verify Claude Code discovers the skill**

Open Claude Code in a fresh conversation. Say: "创建 llm-wiki 知识库".

Expected: Claude invokes the `llm-wiki-starter` Skill (visible via Skill tool call in the UI). If Claude does not invoke it, check that the description's keywords match the user's phrase and that the file exists at `$HOME/.claude/skills/llm-wiki-starter/SKILL.md`.

- [ ] **Step 3: Verify install.sh still works end-to-end (regression check)**

In a scratch dir:

```bash
cd /tmp && rm -rf wiki-regression && mkdir wiki-regression && cd wiki-regression
bash "$REPO_DIR/install.sh" --dev --yes --name regression-test --lang en
ls regression-test/.obsidian/plugins/
cat regression-test/.obsidian/community-plugins.json
```

Expected:

- 17 plugin directories in `.obsidian/plugins/` (subject to network — some may be missing with ⚠ warnings)
- `community-plugins.json` is an array of the successfully installed ids
- `claudian` is first in the list (as before)

If regressed, inspect `read_plugin_manifest` output; debug manifest path resolution.

- [ ] **Step 4: Verify json-canvas soft-disable directive is visible**

Grep:

```bash
grep -n "obsidian-canvas-creator" skills/llm-wiki-starter/SKILL.md skills/llm-wiki-starter/references/06-install-skills.md
```

Expected: matches in both files (constraint directive).

- [ ] **Step 5: Commit verification notes (if any fixes made)**

If verification found issues and you fixed them, commit per-fix with precise commit messages. If everything passed on first try, no commit needed here.

---

## Task 17: Push and open PR

**Files:** none (git operations)

- [ ] **Step 1: Review all commits on the branch**

```bash
git log main..HEAD --oneline
```

Expected: ~13 commits (one per Task 1-13, plus optionally Task 15 and verification fixes).

- [ ] **Step 2: Push the branch**

```bash
git push -u origin HEAD
```

- [ ] **Step 3: Open PR**

```bash
gh pr create --title "feat: add llm-wiki-starter Skill (AI-agent-driven install path)" --body "$(cat <<'EOF'
## Summary

- Adds a Skill at `skills/llm-wiki-starter/` (or repo root `llm-wiki-starter/` if the fallback was triggered) that guides any AI Agent to scaffold an LLM Wiki end-to-end.
- Extracts the 17-plugin list + Minimal theme into `plugin-manifest.json` as the single source of truth; `install.sh` refactored to read it.
- Flips Agent Skills detection order to prefer `~/.agents/` over `~/.claude/`.
- `README.md` / `README.zh-CN.md` now present Option A (Skill) and Option B (bash) paths.

## Test plan

- [ ] Skill installs via `npx -y skills add eleven-net-cn/llm-wiki-starter -g -y`
- [ ] Claude Code auto-triggers the Skill on "创建 llm-wiki 知识库" / "create llm wiki"
- [ ] `install.sh` still installs 17 plugins (regression check in a scratch dir)
- [ ] Agent Skills detection reports ✓ when installed in either `~/.agents/` or `~/.claude/`
- [ ] json-canvas soft-disable directive visible in SKILL.md and 06-install-skills.md

Spec: `docs/superpowers/specs/2026-05-03-llm-wiki-starter-skill-design.md`

🤖 Generated with [Claude Code](https://claude.com/claude-code)
EOF
)"
```

Capture the PR URL in the output.

---

## Self-review checklist

Run the following before signalling plan complete:

1. **Spec coverage:** Every major section of the spec has a matching task. Layout (Task 2+14/15), frontmatter (Task 2), 7 stages (Tasks 3-10), AI matrix (Task 5), agent-skills path order (Task 11), manifest DRY (Tasks 1+11), tarball template (Task 9), Web Clipper detect (Task 6), finalize summary (Task 10), `~/.agents/` priority (Task 11), json-canvas constraint (Tasks 2+8), README options (Tasks 12+13).
2. **Placeholder scan:** No "TBD", "TODO", "add validation", "similar to above" without repeat. All code blocks contain concrete code.
3. **Type consistency:** `read_plugin_manifest`, `read_theme_manifest`, `plugin-manifest.json`, `SKILL.md`, `references/` — names consistent across tasks.
4. **Gated fallback:** Task 14 decides whether Task 15 runs — explicitly documented.
5. **Idempotency:** Every install step checks existence first; plan does not assume first-time run.
