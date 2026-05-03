English | [简体中文](./README.zh-CN.md)

# llm-wiki-starter

One command to scaffold an [Andrej Karpathy's LLM Wiki](https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f) AI knowledge base.

Auto-installs Claude Code + Obsidian + recommended plugins (Skills & Plugins & Theme & Shortcuts), so AI can continuously build and maintain your personal knowledge system.

Compatible with Claude Code, Codex, Copilot, Gemini CLI, OpenCode, and other mainstream AI agents out of the box.

![ai-wiki](./assets/ai-wiki.png)

## Installation

Pick one of two paths:

### Option A — Skill-based (recommended for AI Agent users)

Install the Skill once, then any AI CLI (Claude Code / Codex / Copilot CLI / Gemini CLI / OpenCode) can scaffold the wiki for you:

```bash
npx -y skills add eleven-net-cn/llm-wiki-starter -g -y
```

Then in your AI CLI say **"create llm wiki"** (中文："创建 llm-wiki 知识库"), or run `/llm-wiki-starter`.

The Agent will detect what's already installed and guide you through the rest.

**Skill command parameters** (all optional; bare `/llm-wiki-starter` runs interactively. Names mirror `install.sh`.):

| Flag | Default | Behavior |
|------|---------|----------|
| `--bash` | off | **Power-user shortcut.** Bypass the AI 6-stage SOP — pipe `install.sh` directly via `curl \| bash`, forwarding the other flags. Massive token savings, same end result. |
| `--name <wiki-name>` | (interactive prompt) | Wiki directory name |
| `--lang <en\|zh>` | `en` | Template language overlay |
| `--dir <path>` | `$(pwd)` | Parent directory; vault created at `<dir>/<name>` |
| `--only-tools` | off | Install tools / skills / Obsidian only — no wiki created |
| `--only-wiki` | off | Skip tool installs; create the wiki + configure plugins (assumes tools already present) |
| `--only-obsidian` | off | Skip tools and wiki creation; install plugins + theme into an existing vault at `--dir` |

The three `--only-*` flags are mutually exclusive.

Examples:

```
/llm-wiki-starter                                                    # interactive, full SOP
/llm-wiki-starter --bash --name research-wiki --lang zh              # fast, non-interactive, no AI walkthrough
/llm-wiki-starter --name research-wiki --lang zh                     # interactive, AI-guided
/llm-wiki-starter --only-tools                                       # just install tools
/llm-wiki-starter --only-wiki --name fresh-wiki --lang en            # tools assumed present, just scaffold a wiki
/llm-wiki-starter --only-obsidian --dir ~/Documents/CODE/my-wiki     # configure plugins on an existing vault
```

#### Skill usage tips

- **Trigger reliability**: `/llm-wiki-starter` always works. Natural language ("create llm wiki", "创建 llm-wiki 知识库") also triggers, but include the word **"llm-wiki"** or **"本地"** to disambiguate from competing skills (lark-wiki, wiki-ingest, etc.). If it doesn't load via natural language, fall back to the explicit slash command.
- **Bare command discovery**: bare `/llm-wiki-starter` (no params) prints a single-line hint of all available flags before starting interactive prompts — that's your inline help.
- **Each invocation creates a NEW wiki**: re-running with the same name will be re-prompted; tools / skills / Obsidian / plugins detection is idempotent and skips already-installed items.
- **Pick the mode that matches what changed**:
  - First time on a fresh machine → bare `/llm-wiki-starter` (or `--bash` if you want non-interactive)
  - Already have tools, just want a new wiki → `--only-wiki --name <new-wiki>`
  - Re-install plugins/theme on an existing vault (e.g. after Obsidian Safe Mode reset) → `--only-obsidian --dir <existing-vault>`
- **`--bash` mode requirements**: needs `curl`, `bash` shell, network access to GitHub. Windows users must run from Git Bash or WSL2 (cmd.exe / PowerShell can't pipe to bash).
- **Update the Skill**: re-running `npx -y skills add eleven-net-cn/llm-wiki-starter -g -y` re-clones and overwrites the local copy at `~/.agents/skills/llm-wiki-starter/` (and the `~/.claude/skills/` symlink).
- **Behind GFW**: install via `npx skills add` uses `git clone`, and `--bash` mode uses `curl`. Configure both: `git config --global http.proxy http://127.0.0.1:<port>` AND shell `export https_proxy=http://127.0.0.1:<port>`. Setting only one of them will leave the other tool unable to reach GitHub.
- **Cross-CLI**: the same Skill file is symlinked under `~/.agents/skills/` and `~/.claude/skills/`, so Claude Code, Codex, Gemini CLI, Cursor, Copilot CLI, and OpenCode all see it without re-installing.
- **Canvas guidance lives in the new vault**: the generated `AGENTS.md` tells future AI sessions to use `obsidian-canvas-creator` (from `axtonliu/visual-skills`) for `.canvas` creation — you don't need to repeat that yourself.

### Option B — One-shot bash script

```bash
curl -fsSL https://raw.githubusercontent.com/eleven-net-cn/llm-wiki-starter/main/install.sh | bash
```
![create-ai-wiki](./assets/create-ai-wiki.svg)

> **Windows users**: Run the installer from **Git Bash** (recommended) or **WSL2** — `cmd.exe` and PowerShell cannot execute bash scripts. Install [Git for Windows](https://git-scm.com/download/win) (provides Git Bash + curl), then run `git config --global core.autocrlf input` to avoid `bad interpreter` errors. The installer auto-detects winget / Chocolatey / Scoop to fetch Obsidian, Node.js and Git.

**With options:**

```bash
# Only detect and install global tools (Claude Code, Obsidian, NodeJS, Agent Skills, etc.)
curl -fsSL https://raw.githubusercontent.com/eleven-net-cn/llm-wiki-starter/main/install.sh | bash -s -- --only-tools

# Skip global tools detection/installation, only create wiki knowledge base
curl -fsSL https://raw.githubusercontent.com/eleven-net-cn/llm-wiki-starter/main/install.sh | bash -s -- --only-wiki

# Skip tools and wiki creation, only configure Obsidian (plugins, theme, shortcuts) in current vault
curl -fsSL https://raw.githubusercontent.com/eleven-net-cn/llm-wiki-starter/main/install.sh | bash -s -- --only-obsidian
```

### Options

Supported options (use as needed):

| Option | Description | Default |
|--------|-------------|---------|
| `--name <name>` | Wiki name | `my-wiki` |
| `--dir <directory>` | Target directory | `./<name>` |
| `--lang <en\|zh>` | Wiki language | `en` |
| `--yes, -y` | Skip all prompts, use defaults | - |
| `--only-tools` | Install tools only, without creating wiki | - |
| `--only-wiki` | Create wiki and Obsidian config only, without installing tools | - |
| `--only-obsidian` | Configure Obsidian in existing vault only | - |

### What Gets Installed

Detects what's already on your system and only installs what's missing:

**Tools & Skills**

- ✅ **Claude Code** — Recommended AI agent
- ✅ **Node.js** — Runtime for Claude Code and Skills CLI
- ✅ **Obsidian** — Wiki editor and visual graph viewer
- ✅ **[kepano/obsidian-skills](https://github.com/kepano/obsidian-skills)** — Obsidian Markdown, CLI interaction, Bases database views, web scraping (defuddle)
- ✅ **[axtonliu/visual-skills](https://github.com/axtonliu/axton-obsidian-visual-skills)** — Excalidraw diagrams, Mermaid charts, Obsidian Canvas, JSON Canvas
- ✅ **Git** — Version control (optional)

> Skills are installed globally via [Skills CLI](https://github.com/vercel-labs/skills), shared across agents.

**Obsidian**

- **Plugins** (17 plugins: 9 Core + 8 UX, auto-configured with wiki)

    Core plugins (required for llm-wiki functionality):

    - ✅ **[Claudian](https://github.com/YishenTu/claudian)** — Embed Claude Code / Codex / OpenCode agents in vault, sidebar chat with full agentic capabilities
    - ✅ **Dataview** — SQL-like queries on page frontmatter
    - ✅ **Templater** — Template system for new pages
    - ✅ **Linter** — Automatic Markdown formatting
    - ✅ **Custom Sort** — File explorer ordering via sortspec
    - ✅ **Obsidian Git** — Auto git commit/push (requires Git)
    - ✅ **Tag Wrangler** — Rename, merge, and manage tags
    - ✅ **Strange New Worlds** — Show wikilink reference counts
    - ✅ **Homepage** — Set a landing page on vault open

    UX plugins (enhance Obsidian editing experience):

    - ✅ **Omnisearch** — Fuzzy search across vault
    - ✅ **Switcher++** — Quick switcher with headings navigation
    - ✅ **Minimal Theme Settings** — Minimal theme configuration
    - ✅ **Hider** — Hide UI elements for cleaner interface
    - ✅ **Editing Toolbar** — MS Word-like toolbar + F11 fullscreen shortcuts
    - ✅ **Excalidraw** — Hand-drawn style diagrams
    - ✅ **Quiet Outline** — Enhanced outline view
    - ✅ **Open in Terminal** — Open vault in terminal

- **Theme**

    ✅ **Minimal** — Clean, distraction-free theme (auto-downloaded)

- **Key Shortcuts**

    - `Cmd+Shift+F` → Omnisearch (fuzzy search)
    - `Cmd+R` → Quick switcher (headings)
    - `Cmd+F11` → Workplace fullscreen
    - `Cmd+Shift+F11` → Editor fullscreen focus

**Browser Extension (recommended)**

- **[Obsidian Web Clipper](https://chromewebstore.google.com/detail/obsidian-web-clipper/cnjifjpddelmedmihgijeibhnjfabmlf)** — Clip web articles directly to `raw/inbox/` for LLM ingestion

## Getting Started

```bash
# Open in Obsidian
cd my-wiki && open -a Obsidian .

# Start AI agent (also works with codex / copilot / gemini, etc.)
claude
```

Then chat with the AI:

- **Ingest** → `Ingest this article: https://example.com/some-article`
- **Query** → `What is the relationship between X and Y?`
- **Lint** → `Run a health check on the wiki`

## Wiki Structure

```
my-wiki/
├── raw/                     # Immutable source materials (LLM read-only)
│   ├── inbox/               # Web Clipper inbox (auto-sorted on ingest)
│   ├── <domain>/            # Organized by knowledge domain
│   └── assets/              # Images, attachments
├── wiki/                    # LLM-maintained knowledge base
│   ├── <domain>/            # Domain-specific compiled pages
│   ├── concepts/            # Concept definition pages
│   ├── summaries/           # Source material summaries
│   ├── synthesis/           # Cross-cutting analysis
│   ├── archived/            # Deprecated pages
│   └── assets/excalidraw/   # Diagrams
├── canvas/                  # JSON Canvas visual maps
├── templates/               # Page templates (one per type, used by LLM)
├── AGENTS.md                # Wiki schema (single source of truth)
└── CLAUDE.md                # Claude Code config (imports AGENTS.md)
```

> **Tip**: Domain directories (e.g. `AI Agent/`, `Machine Learning/`) are created automatically during your first ingest. Just tell the AI what domain your knowledge belongs to — or let it decide based on the content.

## What is LLM Wiki?

[LLM Wiki](https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f) is a knowledge management pattern proposed by Andrej Karpathy: instead of traditional RAG that retrieves from scratch every query, the LLM **incrementally builds and maintains a persistent wiki** — cross-references are established automatically, contradictions are flagged, and synthesis is continuously updated. Each new source makes the wiki richer.

**Suitable for**: personal knowledge management, technical research, domain learning notes, team knowledge bases — any scenario where you want AI to help you accumulate and organize knowledge over time.

**How it works**: [Claude Code](https://claude.ai/claude-code) serves as the AI agent that reads, writes and maintains the wiki; [Obsidian](https://obsidian.md) serves as the visual editor and reader. You chat with the AI to ingest sources, query knowledge, and run health checks — while browsing and navigating the wiki graph in Obsidian.

**Three-layer architecture**: `raw/` (immutable sources) → `wiki/` (LLM-maintained pages) → Schema (`AGENTS.md`)

**Three operations**: **Ingest** (add knowledge) → **Query** (ask questions) → **Lint** (health check)

## Credits

- [Andrej Karpathy — LLM Wiki](https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f)

## License

[MIT](LICENSE)
