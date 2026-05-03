# Stage 2: Install AI CLIs

Present 5 options as multi-select. Pre-check Claude Code (default).

Do NOT prompt for login, API keys, or any post-install configuration. After each install succeeds, move on.

## The 5 options

| # | CLI | Default? | Detect | Install |
|---|---|---|---|---|
| 1 | **Claude Code** | ✓ | `command -v claude` | `npm install -g @anthropic-ai/claude-code` |
| 2 | **Codex CLI** |   | `command -v codex` | `npm install -g @openai/codex` |
| 3 | **GitHub Copilot CLI** |   | `gh extension list \| grep -q gh-copilot` | `gh extension install github/gh-copilot` (requires `gh`) |
| 4 | **Gemini CLI** |   | `command -v gemini` | `npm install -g @google/gemini-cli` |
| 5 | **OpenCode** |   | `command -v opencode` | `curl -fsSL https://opencode.ai/install \| bash` |

Note: exact npm package names may evolve. If the install command above reports "package not found", ask the user to confirm the current package name or skip this tool.

## Multi-select interaction

Using your host CLI's native mechanism (e.g. AskUserQuestion for Claude Code):

- Question: "Which AI CLIs to install? (multi-select, Claude Code pre-checked)"
- Options: five rows above
- Let user confirm / modify / proceed.

## GitHub CLI (`gh`) prerequisite for Copilot

Copilot CLI is a `gh` extension, not a standalone binary. If user picks Copilot and `gh` is missing, install `gh` first:

| OS | Command |
|---|---|
| macOS | `brew install gh` |
| Linux (apt) | `sudo apt-get install -y gh` (may need `apt-key` setup first — see cli.github.com/manual/installation) |
| Linux (dnf) | `sudo dnf install -y gh` |
| Windows | `winget install GitHub.cli` |

After `gh` is present, also tell the user: "Run `gh auth login` later to use Copilot CLI" — this is informational only; do not invoke it in this Skill.

## Handling failures

If one CLI's install fails (network, registry, whatever): record to manual-install list, continue with the next selected CLI. Do not abort the whole stage.

## Post-stage

After attempting all selected CLIs, print summary:

```
AI CLIs:
  ✓ Claude Code (version)
  ✓ Codex CLI
  ⚠ Gemini CLI — install failed, run: npm install -g @google/gemini-cli
```

Then proceed to Stage 3.
