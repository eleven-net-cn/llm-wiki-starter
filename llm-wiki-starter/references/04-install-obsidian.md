# Stage 3: Install Obsidian app + Web Clipper

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

3. Do not prompt the user to install it right now; continue to Stage 4. Stage 6 summary will remind them.
