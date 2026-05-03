# Stage 6: Finalize

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

Print ONE structured summary, then stop. Scale to actual install results — only show non-empty sections.

Item rule: each tool / skill / plugin gets ONE line by name. No aggregate phrases like "Both Agent Skills installed". No internal AI-coordination notes (e.g. json-canvas constraint — that lives in the vault's `AGENTS.md`, not the user-facing summary).

```
✓ Wiki created: <WIKI_DIR> (lang: <LANG>)

Installed this run:
  ✓ <tool name and version, one per line>
  ✓ kepano/obsidian-skills
  ✓ axtonliu/visual-skills
  ✓ 17 Obsidian plugins + Minimal theme

Skipped (already installed):
  - <tool name and version, one per line>

Manual install required:
  ⚠ Web Clipper: https://obsidian.md/clip (install in your browser)
  ⚠ <other manual items only if they actually failed>

Quick start:
  1. cd <WIKI_DIR>
  2. Open as Obsidian vault:
       macOS:   open -a Obsidian .
       Linux:   obsidian .
       Windows: start obsidian .
  3. Start chatting with your AI agent in this directory and try:
       "ingest this article: <url>"
       "what's the relationship between X and Y?"
       "run a wiki lint"
```

Drop entire sections when empty (no "Manual install required:" header if Web Clipper was detected and nothing else failed).

Stop after the summary. Do NOT append re-triggering tips, "you can run me again" hints, or any forward-looking narration — global principle #8. The summary is the end.
