English | [简体中文](./README.md)

# llm-wiki-starter

Create an LLM Wiki knowledge base in one command — based on [Andrej Karpathy's LLM Wiki pattern](https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f).

```bash
curl -fsSL https://raw.githubusercontent.com/eleven-net-cn/llm-wiki-starter/main/install.sh | bash
```

## What is LLM Wiki?

Traditional RAG discovers knowledge from scratch on every query. LLM Wiki is different — the LLM **incrementally builds and maintains a persistent wiki**, where cross-references are established, contradictions are flagged, and synthesis is continuously updated. Each new source makes the wiki richer.

**Three-layer architecture**: `raw/` (immutable sources) → `wiki/` (LLM-maintained) → Schema (`AGENTS.md`)

**Three operations**: Ingest → Query → Lint

## Install

### One-line install

```bash
curl -fsSL https://raw.githubusercontent.com/eleven-net-cn/llm-wiki-starter/main/install.sh | bash
```

The installer will:
1. Create the wiki directory structure
2. Detect what's already installed on your system
3. Show an installation plan and ask for confirmation
4. Install missing tools (Obsidian, plugins, Node.js, Claude Code, Skills, Git)
5. Initialize a Git repository (if Git is available)

If you decline installation, the script prints a manual install guide with official links.

### Manual clone

```bash
git clone https://github.com/eleven-net-cn/llm-wiki-starter my-wiki
cd my-wiki
bash install.sh
```

The script detects it's inside the template repo and skips the download step.

### Options

| Option | Description | Default |
|--------|-------------|--------|
| `--name <name>` | Wiki name | `my-wiki` |
| `--dir <directory>` | Target directory | `./<name>` |
| `--lang <zh\|en>` | Wiki language | `zh` |
| `--non-interactive` | Skip all prompts, use defaults | - |
| `--skip-install` | Only create structure, skip tool installation | - |

Environment variable `LLM_WIKI_DIR` can also specify the target directory.

```bash
# Non-interactive install
bash install.sh --non-interactive --name my-ai-wiki

# English wiki
bash install.sh --lang en --name my-wiki

# Structure only (CI / quick test)
bash install.sh --name test-wiki --dir /tmp/test --skip-install
```

## Quick Start

```bash
# 1. Install
curl -fsSL https://raw.githubusercontent.com/eleven-net-cn/llm-wiki-starter/main/install.sh | bash

# 2. Open in Obsidian
cd my-wiki && open -a Obsidian .

# 3. Start AI agent
claude

# 4. Ingest your first resource
> Ingest this article: https://example.com/some-article

# 5. Query your wiki
> What is the relationship between X and Y?

# 6. Run health check
> Run a lint check on the wiki
```

## Generated Structure

```
my-wiki/
├── raw/                     # Immutable source materials
│   ├── inbox/               # Web Clipper inbox
│   ├── <domain>/            # Organized by knowledge domain
│   └── assets/              # Images, attachments
├── wiki/                    # LLM-maintained knowledge base
│   ├── <domain>/            # Domain-specific compiled pages
│   ├── concepts/            # Concept definition pages
│   ├── summaries/           # Source material summaries
│   ├── synthesis/           # Cross-cutting analysis
│   ├── archived/            # Deprecated pages
│   ├── assets/excalidraw/   # Diagrams
│   ├── Index.md             # Content index
│   ├── Changelog.md         # Operation timeline
│   └── Overview.md          # Landing page
├── canvas/                  # JSON Canvas visual maps
├── CLAUDE.md                # Claude Code schema (imports AGENTS.md)
├── AGENTS.md                # Shared wiki schema (SSOT)
└── README.md
```

Domain directories are created automatically by the LLM during the first ingest.

## What Gets Installed

### Tools

| Tool | Purpose | Install method |
|------|---------|---------------|
| **Obsidian** | Wiki editor & viewer | `brew install --cask obsidian` / snap |
| **Node.js** | Required for Claude Code & Skills CLI | brew / apt / dnf |
| **Claude Code** | AI agent (recommended) | `npm install -g @anthropic-ai/claude-code` |
| **Git** | Version control (optional) | xcode-select / brew / apt |

### Obsidian Plugins

| Plugin | Purpose | Priority |
|--------|---------|----------|
| **Dataview** | SQL-like queries on frontmatter | Required |
| **Templater** | Template system | Required |
| **Obsidian Git** | Auto git commit/push | Required (if Git available) |
| **Linter** | Markdown formatting | Required |
| **Custom Sort** | File explorer ordering via sortspec | Required |
| **Tag Wrangler** | Tag management | Recommended |
| **Strange New Worlds** | Show wikilink reference counts | Recommended |
| **Homepage** | Set a landing page | Recommended |

### Claude Code Skills

Installed globally via [Skills CLI](https://github.com/vercel-labs/skills) (`npx skills add -g -y`), auto-linked to all detected agents.

| Skills | Purpose |
|--------|---------|
| **[kepano/obsidian-skills](https://github.com/kepano/obsidian-skills)** | Obsidian markdown, CLI interaction, web scraping (defuddle) |
| **[axtonliu/visual-skills](https://github.com/axtonliu/axton-obsidian-visual-skills)** | Excalidraw diagrams, Mermaid charts, Canvas maps |

### Browser Extension (Recommended)

| Extension | Purpose |
|-----------|----------|
| **[Obsidian Web Clipper](https://chromewebstore.google.com/detail/obsidian-web-clipper/cnjifjpddelmedmihgijeibhnjfabmlf)** | Clip web articles directly to `raw/inbox/` for LLM ingestion |

## Supported AI Agents

The generated schema works with any of these agents:

| Agent | Schema file | Link |
|-------|-------------|------|
| **Claude Code** | `CLAUDE.md` → imports `AGENTS.md` | [claude.ai/claude-code](https://claude.ai/claude-code) |
| **OpenCode** and more | `AGENTS.md` | [github.com/anomalyco/opencode](https://github.com/anomalyco/opencode) |

## Comparison

| | llm-wiki-starter | [llm-wikid](https://github.com/shannhk/llm-wikid) | Manual setup |
|---|---|---|---|
| Setup time | **5 minutes** | 20 minutes | 2–4 hours |
| Language | Chinese / English | English | Custom |
| Domain | Domain-agnostic | Content/marketing | Write your own schema |
| Architecture | Three-layer (raw/wiki/schema) | Two-layer (KBL+BF) | Custom |
| Agent support | Claude Code + OpenCode + Gemini CLI | Claude Code | Self-configured |
| Suite install | Fully automated (Obsidian + plugins + Skills) | Manual | Manual |

## License

[MIT](LICENSE)
