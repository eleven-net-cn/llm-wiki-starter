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
