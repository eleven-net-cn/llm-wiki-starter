English | [简体中文](./README.zh-CN.md)

# llm-wiki-starter

## What is LLM Wiki?

[LLM Wiki](https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f) is a knowledge management pattern proposed by Andrej Karpathy: instead of traditional RAG that retrieves from scratch every query, the LLM **incrementally builds and maintains a persistent wiki** — cross-references are established automatically, contradictions are flagged, and synthesis is continuously updated. Each new source makes the wiki richer.

**Suitable for**: personal knowledge management, technical research, domain learning notes, team knowledge bases — any scenario where you want AI to help you accumulate and organize knowledge over time.

**How it works**: [Claude Code](https://claude.ai/claude-code) serves as the AI agent that reads, writes and maintains the wiki; [Obsidian](https://obsidian.md) serves as the visual editor and reader. You chat with the AI to ingest sources, query knowledge, and run health checks — while browsing and navigating the wiki graph in Obsidian.

**Three-layer architecture**: `raw/` (immutable sources) → `wiki/` (LLM-maintained pages) → Schema (`AGENTS.md`)

**Three operations**: **Ingest** (add knowledge) → **Query** (ask questions) → **Lint** (health check)

## Install

```bash
curl -fsSL https://raw.githubusercontent.com/eleven-net-cn/llm-wiki-starter/main/install.sh | bash
```

| Option | Description | Default |
|--------|-------------|---------|
| `--name <name>` | Wiki name | `my-wiki` |
| `--dir <directory>` | Target directory | `./<name>` |
| `--lang <en\|zh>` | Wiki language | `en` |
| `--non-interactive` | Skip all prompts, use defaults | - |
| `--skip-install` | Only create structure, skip tool installation | - |

## What Gets Installed

The installer detects what's already on your system and only installs what's missing:

**Tools**

- ✅ **Claude Code** — AI agent that maintains the wiki
- ✅ **Obsidian** — Wiki editor and visual graph viewer
- ✅ **Node.js** — Runtime for Claude Code and Skills CLI
- ✅ **Git** — Version control (optional)

**Obsidian Plugins**

- ✅ **Dataview** — SQL-like queries on page frontmatter
- ✅ **Templater** — Template system for new pages
- ✅ **Linter** — Automatic Markdown formatting
- ✅ **Custom Sort** — File explorer ordering via sortspec
- ✅ **Obsidian Git** — Auto git commit/push (requires Git)
- ✅ **Tag Wrangler** — Rename, merge, and manage tags
- ✅ **Strange New Worlds** — Show wikilink reference counts
- ✅ **Homepage** — Set a landing page on vault open

**Claude Code Skills** (installed globally via [Skills CLI](https://github.com/vercel-labs/skills), shared across agents)

- ✅ **[kepano/obsidian-skills](https://github.com/kepano/obsidian-skills)** — Obsidian markdown, CLI interaction, web scraping (defuddle)
- ✅ **[axtonliu/visual-skills](https://github.com/axtonliu/axton-obsidian-visual-skills)** — Excalidraw diagrams, Mermaid charts, Canvas maps

**Browser Extension (recommended)**

- ✅ **[Obsidian Web Clipper](https://chromewebstore.google.com/detail/obsidian-web-clipper/cnjifjpddelmedmihgijeibhnjfabmlf)** — Clip web articles directly to `raw/inbox/` for LLM ingestion

## Quick Start

```bash
# Open in Obsidian
cd my-wiki && open -a Obsidian .

# Start AI agent
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
├── AGENTS.md                # Wiki schema (single source of truth)
└── CLAUDE.md                # Claude Code config (imports AGENTS.md)
```

> **Tip**: Domain directories (e.g. `AI Agent/`, `Machine Learning/`, `Web Dev/`) are created automatically during your first ingest. Just tell the AI what domain your knowledge belongs to — or let it decide based on the content.

## Credits

- [Andrej Karpathy — LLM Wiki](https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f)

## License

[MIT](LICENSE)
