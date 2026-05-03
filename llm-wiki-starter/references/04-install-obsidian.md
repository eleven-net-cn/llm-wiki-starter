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

**Cannot be installed via CLI** — browser extensions require user approval in-browser.

1. Detect (per `references/01-detect-tools.md`). If any browser's extension folder contains the Obsidian Web Clipper ID, mark `WEB_CLIPPER_INSTALLED=true` for the finalize summary and move on silently.
2. If not detected, mark `WEB_CLIPPER_INSTALLED=false` for finalize. **Do not print anything to the user during this stage** — the summary in Stage 6 will surface it once. (Global principle #10.)
