# <Wiki Name>

A personal knowledge base powered by the [LLM Wiki pattern](https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f).

## Quick Start

1. Open this folder in [Obsidian](https://obsidian.md)
2. Start your AI agent: `claude`
3. Begin with your first ingest

## Operations

### 1. Ingest — Add knowledge

Place source materials in `raw/` or provide a URL directly:

```
Ingest this article: https://example.com/some-article
Ingest all new materials
```

The LLM reads the source, creates summaries, extracts concepts, adds cross-references, and updates the index.

### 2. Query — Ask questions

```
What is the relationship between X and Y?
Compare A and B
Summarize everything we know about topic Z
```

The LLM consults wiki pages and synthesizes answers with `[[wikilink]]` citations.

### 3. Lint — Health check

```
Run a health check on the wiki
```

Checks for orphan pages, dead links, stale content, missing concepts, and tag violations.

## Structure

- `raw/` — Source materials (human-managed, immutable)
- `wiki/` — LLM-compiled knowledge pages
- `CLAUDE.md` — Schema for [Claude Code](https://claude.ai/claude-code)
- `AGENTS.md` — Shared schema for [AGENTS.md-compatible](https://github.com/anthropics/AGENTS-md-spec) agents (Codex, Copilot, Gemini CLI, OpenCode, etc.)
