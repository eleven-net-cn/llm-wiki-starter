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

Print a structured summary to stdout. Scale to the user's actual install results.

```
✓ Wiki created: <WIKI_DIR> (lang: <LANG>)

Installed this run:
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

Replace bracketed placeholders with actual values.

## Re-triggering

Tell the user: "You can re-run this workflow anytime with `/llm-wiki-starter` — I'll skip everything already installed."
