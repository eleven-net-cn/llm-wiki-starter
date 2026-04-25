# <Wiki Name> — LLM Wiki Schema

> Built on [Andrej Karpathy's LLM Wiki pattern](https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f).
> This file defines how the LLM maintains this knowledge base.
> Humans curate source materials and ask questions; the LLM handles all
> summarization, cross-referencing, archival, and maintenance.
>
> This is the shared schema (Single Source of Truth). Claude Code imports it
> via `@AGENTS.md`. Codex, Copilot, OpenCode, Gemini CLI, etc. read it directly.
> **Never duplicate this content into CLAUDE.md.**

## Architecture

Three-layer structure:

1. **`raw/`** — Immutable source documents. The LLM reads but never writes here.
2. **`wiki/`** — LLM-generated and maintained markdown pages. The LLM fully owns this layer.
3. **This file (`AGENTS.md`)** — Schema specification. Defines structure, conventions, and workflows.

## Directory Structure

```
<wiki-name>/
├── raw/                        # Layer 1: Source materials (immutable)
│   ├── inbox/                  # Web Clipper inbox (unified entry point)
│   ├── assets/                 # Images, attachments
│   └── <domain>/               # Organized by knowledge domain
├── wiki/                       # Layer 2: LLM-maintained wiki
│   ├── <domain>/               # Domain-specific compiled pages
│   ├── concepts/               # Concept pages (cross-domain knowledge axis)
│   ├── summaries/              # One summary per ingested raw file
│   ├── synthesis/              # Cross-cutting analysis and insights
│   ├── archived/               # Deprecated pages
│   ├── assets/excalidraw/      # Excalidraw diagrams
│   ├── Index.md                # Content index (LLM-maintained)
│   ├── Changelog.md            # Operation timeline log
│   └── Overview.md             # Wiki landing page
├── canvas/                     # JSON Canvas visual maps
├── templates/                  # Page templates (one per type, used by LLM)
├── CLAUDE.md                   # Claude Code schema (imports this file)
├── AGENTS.md                   # This schema file
└── README.md                   # Repository documentation
```

Domain directories under `raw/` and `wiki/` are created automatically during the first ingest — no need to pre-configure them.

## Page Format

### Frontmatter Spec

Every wiki page must include this frontmatter:

```yaml
---
title: Page Title
type: entity | concept | topic | comparison | source | synthesis
tags: [tag1, tag2, tag3]
aliases: [alt-name-1, alt-name-2]     # Optional, for Obsidian search/linking
created: YYYY-MM-DD
updated: YYYY-MM-DD
sources:
  - "[[Summary：source-name]]"         # Always use wikilink format
confidence: high | medium | low
related_concepts: []                   # Optional, concept pages only
source_url: https://...                # Optional, source pages only
media: article | paper | video         # Optional, source pages only
---
```

### Body Structure

When creating a wiki page, **read `templates/<type>.md` first** to get the matching template, then strictly follow its section structure. Do not invent your own sections.

| type | Template file | Purpose |
|------|--------------|---------|
| entity | `templates/entity.md` | Products, projects, organizations, people |
| concept | `templates/concept.md` | Concept definitions |
| topic | `templates/topic.md` | Domain topics, comprehensive guides |
| comparison | `templates/comparison.md` | Comparative analysis |
| source | `templates/source.md` | Source material summaries |
| synthesis | `templates/synthesis.md` | Cross-cutting analysis & insights |

### Page Naming

- **Filename = frontmatter `title`**: filename must match the title exactly
- Half-width `:` is not allowed in macOS filenames — use full-width `：` (e.g., `Summary：Topic.md`)
- Summary pages: `Summary：` prefix + short name
- Concept pages: descriptive name, e.g., `Transformer.md`, `RAG (Retrieval-Augmented Generation).md`

### Concept Page Principles

- 100–250 lines each, focused on authoritative definitions
- `confidence: high` when backed by `raw/` sources; `confidence: medium` when based on training knowledge alone
- If a detailed domain page already exists, keep the concept page as a concise definition + link — don't duplicate content
- All concept pages must include the `concept` tag

## Tag System

Use a **controlled vocabulary**. Keep tags concise (≤6 words per tag).

**Content-type tags (what form of knowledge is this?):**
`concept`, `tutorial`, `deep-dive`, `overview`, `opinion`, `news`, `tool`, `paradigm`, `anti-pattern`, `case-study`, `benchmark`, `best-practice`

**Meta tags (lifecycle properties):**
`evergreen` (stable, long-lasting), `fast-moving` (changes quickly, review periodically), `foundational` (prerequisite knowledge), `advanced` (requires deep background)

**Domain tags:** Define your own based on your knowledge domain. Keep them consistent.

<!-- Example domain tags for different fields:
  AI:       llm, agent, coding, prompt-engineering, infrastructure, ecosystem, research
  Software: frontend, backend, architecture, devops, database, security, team
  Research: literature, methodology, experiment, data-analysis, writing
-->

**Tag principles:**
- Check existing tags before creating new ones
- One word, one meaning: unify synonyms into a single tag
- Keep vendor/product/protocol names in their original form (e.g., `openai`, `claude-code`)

## Workflows

### 1. Ingest

When the user adds new material to `raw/` and requests ingestion:

1. **Read** the source document completely.
2. **Discuss** key points with the user to confirm emphasis.
3. **Create** a summary page in `wiki/summaries/` with proper frontmatter.

#### URL Direct Ingest

Users can provide a URL directly. The LLM fetches and ingests it:

```
Ingest this article: https://example.com/some-article
```

Flow:
1. Use `defuddle` to extract clean markdown: `npx defuddle parse <url> --markdown`
2. Save the cleaned markdown to `raw/<domain>/` as an immutable source document
3. Continue with the standard ingest flow (steps 1–10)

#### Inbox Ingest

`raw/inbox/` is the **unified inbox** for browser Web Clipper content. When the user says "ingest new materials", the LLM **must first scan** `raw/inbox/`:

1. **Scan** all files in `raw/inbox/`
2. **Read** each file, determine its knowledge domain
3. **Move** the file to the matching `raw/<domain>/` directory
4. **Continue** standard ingest flow for each file

Files are moved out of `raw/inbox/` after processing (no copies kept). Check this directory on every ingest operation.

#### Standard Flow (continued)
4. **Determine domain** — Place the page in the matching directory. If it spans multiple domains, choose the best match and use tags for cross-referencing.
5. **Update or create** entity pages, concept pages, and topic pages in the corresponding domain directory.
6. **Diagram generation** — If the material meets any of these conditions, generate at least one diagram and embed it in the relevant wiki page:
   - Describes a system/framework **architecture** (layers, modules, component topology)
   - Contains an **execution loop** or process (pipelines, cyclic flows)
   - Contains **multi-actor collaboration** (multi-service interaction, message passing)
   - Contains **data flow** (input → processing → output)
   - Contains **hierarchy** or classification (capability stacks, category trees)

   Diagram tool selection: architecture/flow/data-flow → **Excalidraw** (stored in `wiki/assets/excalidraw/`); relationship maps → **JSON Canvas** (stored in `canvas/`); simple sequence/state → **Mermaid** (inline).

   Embed with: `![[diagram-name.excalidraw]]` or Mermaid code block. **Never** use ASCII art.

   Skip when: pure opinion pieces / data rankings; single linear steps (≤3); existing diagram on the same topic can be reused.
7. **Concept extraction** — Identify core concepts in the material:
   - Check if `wiki/concepts/` already has a page for each concept
   - If not, create a new concept page (use concept page format)
   - If yes, update the existing page's sources and related content
8. **Flag contradictions** — If new material conflicts with existing pages, note both positions with citations.
9. **Add cross-references** — Add bi-directional `[[wikilinks]]` between new and existing pages.
10. **Update index and log**:
    - Update `wiki/Index.md` with new page entries
    - Append to `wiki/Changelog.md`:
    ```
    ## [YYYY-MM-DD] ingest | Material Title
    - Source: raw/<domain>/<filename>.md
    - New pages: list
    - Updated pages: list
    - New concepts: list (if any)
    - New diagrams: list (if any)
    - Key insight: one sentence
    ```

### 2. Query

When the user asks a question:

1. **Read** `wiki/Index.md` to find relevant pages.
2. **Read** relevant wiki pages (not raw materials — the wiki is compiled knowledge).
3. **Synthesize** an answer with `[[page]]` citations.
4. **If the answer has substantial value**, suggest saving it as a new wiki page (comparison, synthesis, etc.).
5. **If the wiki lacks relevant information**, state this clearly — then check raw materials or suggest sources to ingest.
6. **Append** to `wiki/Changelog.md`:
    ```
    ## [YYYY-MM-DD] query | Brief question
    - Pages consulted: list
    - Result: answered | saved as wiki/synthesis/page.md | knowledge gap found
    ```

### 3. Lint

When the user requests a health check (or run periodically):

1. **Orphan pages** — Pages with no inbound links.
2. **Dead links** — `[[wikilinks]]` pointing to non-existent pages.
3. **Stale pages** — Not updated in 30+ days and tagged `fast-moving`.
4. **Missing pages** — Concepts mentioned across multiple pages but lacking their own page.
5. **Contradictions** — Conflicting claims across pages (flag for human review).
6. **Tag violations** — Tags not in the controlled vocabulary, duplicates, untagged pages.
7. **Resource coverage** — Raw materials not yet ingested.
8. **Concept coverage** — Concepts frequently mentioned in domain pages but missing from `wiki/concepts/`.
9. **Append** results to `wiki/Changelog.md`.

## Obsidian Integration

This directory is an Obsidian vault. Follow these rules:

- Use `[[wikilinks]]` syntax for cross-references (do not use markdown links for internal pages).
- Use `![[image.png]]` to embed images from `raw/assets/`.
- Respect Obsidian's `.obsidian/` config directory — do not modify it directly.

### Visualization

Wiki pages use diagrams instead of ASCII art, in this priority order:

| Priority | Tool | Use Case | Storage |
|:---:|------|----------|---------|
| 1 | **Excalidraw** | Flowcharts, architecture, data flow, complex logic | `wiki/assets/excalidraw/` |
| 2 | **JSON Canvas** | Knowledge relationship maps, spatial layout | `canvas/` |
| 3 | **Mermaid** | Sequence diagrams, state diagrams, simple inline charts | Inline in wiki pages |

Simple linear flows and comparison tables can stay as text.

**Excalidraw specs:**
- Store in `wiki/assets/excalidraw/`, name as `<topic> <type>.excalidraw.md`
- Embed with: `![[diagram-name.excalidraw]]`
- Unified palette: blue `#a5d8ff` (main flow), green `#b2f2bb` (output), orange `#ffd8a8` (condition), purple `#d0bfff` (extension)
- Font: `fontFamily = 5`, `roughness = 0`
- Fill: `fillStyle = 'solid'` (no hachure / cross-hatch)

### Web Scraping with Defuddle

When ingesting web articles, first extract clean markdown with `defuddle`:
```bash
npx defuddle parse https://example.com/article --markdown
```
Strips navigation, ads, and clutter — saves tokens and produces cleaner source material.

## Confidence Levels

- **high** — Reliable source, multiple corroborating references, stable information.
- **medium** — Single source, or nuances may not be fully captured.
- **low** — Preliminary, based on limited data, or likely to change quickly.

## Constraints

- Never modify files in `raw/`. They are immutable source documents.
- Never fabricate information. Mark `confidence: low` and note uncertainty when unsure.
- Always use the frontmatter format above when creating wiki pages.
- Always update `wiki/Index.md` and `wiki/Changelog.md` after every operation.
- Keep pages focused. Split pages exceeding ~500 lines.
- Prefer updating existing pages over creating new ones when content overlaps.
- The `sources` field in frontmatter must use `[[wikilink]]` format.
- **Preserve source links**: When mentioning GitHub repos, official docs, or authoritative sources, embed clickable URLs inline as `[display name](url)` at first mention — don't collect them in a separate references section.
- **Ingest / lint / query operations only modify wiki pages, never `CLAUDE.md` or `AGENTS.md`.** Schema files are only edited when the user explicitly requests schema changes.

### Knowledge Grouping

When the same knowledge topic has **>1 document** in a directory, group them into a dedicated subfolder. This applies to both `raw/` and `wiki/`.

**Trigger:** When a second document on the same topic appears in a directory, create a subfolder and move all related documents into it.

**Naming:** Folder name = topic name, keep it concise. Use the same folder name in both `raw/` and `wiki/`.

**Exception:** Cross-topic overviews or comparisons stay in the domain root directory.

### Archive

`wiki/archived/` stores deprecated or unmaintained pages. During lint, suggest moving stale pages (30+ days old and tagged `fast-moving`) to `wiki/archived/`. Archived pages keep their original content but add `archived: YYYY-MM-DD` to frontmatter and are removed from `wiki/Index.md`.
