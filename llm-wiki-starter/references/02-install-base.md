# Stage 1: Install base tools

Install these, in order: curl, Node.js, jq, Git. Skip any that `command -v` already finds.

Report progress per tool. On failure, record to manual-install list and continue.

## curl

Required for tarball download in Stage 4. Almost always pre-installed.

- macOS / Linux: pre-installed; if truly missing, `brew install curl` / `apt-get install -y curl` / `dnf install -y curl` / `pacman -S --noconfirm curl`.
- Windows 10+: pre-installed as `curl.exe`. If missing, `winget install curl.curl`.

## Node.js (LTS)

| OS | Command |
|---|---|
| macOS | `brew install node` |
| Linux (apt) | `sudo apt-get update -qq && sudo apt-get install -y -qq nodejs npm` |
| Linux (dnf) | `sudo dnf install -y -q nodejs npm` |
| Linux (pacman) | `sudo pacman -S --noconfirm nodejs npm` |
| Windows (winget) | `winget install OpenJS.NodeJS.LTS --accept-source-agreements --accept-package-agreements` |
| Windows (choco) | `choco install nodejs-lts -y` |
| Windows (scoop) | `scoop install nodejs-lts` |

Verify: `command -v node && node --version` should report v18+.

Fallback: print `https://nodejs.org` for manual install.

## jq

Used by `install.sh` to parse plugin-manifest.json. The Skill itself does not need jq (Agent can read JSON natively).

| OS | Command |
|---|---|
| macOS | `brew install jq` |
| Linux (apt) | `sudo apt-get install -y -qq jq` |
| Linux (dnf) | `sudo dnf install -y -q jq` |
| Linux (pacman) | `sudo pacman -S --noconfirm jq` |
| Windows (winget) | `winget install jqlang.jq --accept-source-agreements --accept-package-agreements` |
| Windows (choco) | `choco install jq -y` |
| Windows (scoop) | `scoop install jq` |

## Git

| OS | Command |
|---|---|
| macOS | `brew install git` (fallback: `xcode-select --install`) |
| Linux (apt) | `sudo apt-get install -y -qq git` |
| Linux (dnf) | `sudo dnf install -y -q git` |
| Linux (pacman) | `sudo pacman -S --noconfirm git` |
| Windows | `winget install Git.Git --accept-source-agreements --accept-package-agreements` |

If Git install fails, Stage 6 will skip `git init` but the wiki is still usable.

## Homebrew (macOS only)

If on macOS and `brew` is missing, before any brew commands:

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
eval "$(/opt/homebrew/bin/brew shellenv 2>/dev/null || /usr/local/bin/brew shellenv 2>/dev/null)"
```

Tell the user this will prompt for sudo and take ~5 minutes.

## Verification checkpoint

After this stage, verify:

```bash
command -v curl && command -v node && command -v jq && command -v git
```

All four should be present. Missing ones are in the manual-install list; print them and proceed to Stage 2.
