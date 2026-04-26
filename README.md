English | [简体中文](./README.zh-CN.md)

# llm-wiki-starter

One command to scaffold an [Andrej Karpathy's LLM Wiki](https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f) AI knowledge base.

Auto-installs Claude Code + Obsidian + recommended plugins (Skills & Plugins & Theme & Shortcuts), so AI can continuously build and maintain your personal knowledge system.

Compatible with Claude Code, Codex, Copilot, Gemini CLI, OpenCode, and other mainstream AI agents out of the box.

## Installation

```bash
curl -fsSL https://raw.githubusercontent.com/eleven-net-cn/llm-wiki-starter/main/install.sh | bash
```
![create-ai-wiki](./create-ai-wiki.svg)

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

**Tools**

- ✅ **Claude Code** — Recommended AI agent
- ✅ **Obsidian** — Wiki editor and visual graph viewer
- ✅ **Node.js** — Runtime for Claude Code and Skills CLI
- ✅ **Git** — Version control (optional)

**Obsidian**

- **Plugins** (16 plugins: 8 Core + 8 UX)

    Core plugins (required for llm-wiki functionality):

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

**Agent Skills** (installed globally via [Skills CLI](https://github.com/vercel-labs/skills), shared across agents)

- ✅ **[kepano/obsidian-skills](https://github.com/kepano/obsidian-skills)** — Obsidian Markdown, CLI interaction, Bases database views, web scraping (defuddle)
- ✅ **[axtonliu/visual-skills](https://github.com/axtonliu/axton-obsidian-visual-skills)** — Excalidraw diagrams, Mermaid charts, Obsidian Canvas, JSON Canvas

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
