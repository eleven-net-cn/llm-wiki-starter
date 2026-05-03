---
name: llm-wiki-starter
description: |
  TRIGGER PHRASES — match ANY of these (case-insensitive):
  · 创建 llm-wiki 知识库 / 创建知识库 / 创建 wiki / 创建 wiki 知识库 / 创建本地知识库
  · 搭建 llm-wiki / 搭建 wiki / 搭建知识库 / 搭建本地知识库 / 搭一个 wiki
  · create llm wiki / scaffold llm wiki / set up llm wiki / build a local wiki / scaffold a knowledge base / set up obsidian wiki / start a new wiki vault
  · /llm-wiki-starter (slash command)

  Scaffolds a NEW LOCAL Obsidian-based LLM Wiki on the user's machine, following Andrej Karpathy's pattern. End-to-end: installs Node/Git/jq, kepano/obsidian-skills, axtonliu/visual-skills, Obsidian app, 17 plugins + Minimal theme; creates a fresh vault from the official template; initializes git. Each invocation produces a NEW vault — re-runs prompt for a fresh name.

  DO NOT match for: 飞书/Lark wiki (lark-wiki handles that), online/hosted wikis (Notion, Confluence, GitHub wiki), ingesting content INTO an existing wiki (wiki-ingest), or generic Obsidian-vault editing (obsidian-markdown / obsidian-cli).
---

# llm-wiki-starter

Guide the user through scaffolding an LLM Wiki knowledge base end-to-end: detect what's already installed, install what's missing across OS/package-manager combinations, create the vault from the official template, and configure Obsidian.

The user is already running an AI CLI to invoke this Skill — do NOT prompt them to install another AI agent.

## When to use

- Natural language: user says 创建 llm-wiki 知识库, 创建知识库, create llm wiki, scaffold llm wiki, set up knowledge base.
- Explicit command: `/llm-wiki-starter` (optionally with `--bash`, `--name <wiki-name>`, `--lang <en|zh>`, `--dir <path>`, `--only-tools`, `--only-wiki`, `--only-obsidian`). See **Parameter reference** below for full semantics.

If explicit command is used with parameters, skip the matching interactive prompts.

## Global principles (apply to every stage)

1. **Detect before install.** Each step: check if target exists → print ✓ skip / ↓ install / ⚠ fail. Never reinstall.
2. **Failures do not block.** On single-item failure, record it to a "manual install" list and continue. Print the full list at the end.
3. **Respect OS and shell.** Detect with `uname -s` (macOS / Linux / Windows-via-Git-Bash). If running under native Windows cmd/PowerShell (no `uname`), use winget/choco/scoop directly — do not assume bash.
4. **Use the host CLI's native interaction.** If you are Claude Code, use AskUserQuestion. If Codex or another CLI, use its native prompt mechanism. Do not hardcode a UI shape.
5. **Idempotent for tools, NOT for wiki creation.** Re-running detects already-installed tools and skips them. But Stage 4 (create wiki) is the workflow's purpose: every invocation MUST prompt for a new wiki name / lang / dir and produce a NEW vault. The existence of a previously-created wiki (e.g. `~/Documents/CODE/my-wiki`) is NOT grounds to skip Stage 4 — ask the user for a new name and create a fresh vault next to it.
6. **Never prompt for login / API keys / tokens / extra AI CLIs.** The user is already running an AI CLI — leave their AI tooling alone.
7. **Windows line endings.** When writing files the user will commit, use LF (Unix) line endings.
8. **Act, don't narrate.** Don't pre-announce what you're about to do. Don't recap which Stage you're in. Don't say "需要确认 X" / "I'll now ask you about Y" / "进入 Stage N" / "稍后会提醒"; just take the action — ask the question, run the command, write the file. The user only needs ONE concise line per outcome (`✓ <name>`, `⚠ <name>: <reason>`), not a play-by-play.
9. **Report each item individually, not in aggregate.** "✓ kepano/obsidian-skills installed" + "✓ axtonliu/visual-skills installed" — not "Both Agent Skills are installed". Lists of items get one line each.
10. **Each warning appears ONCE.** Don't pre-warn at detection time and then re-warn at finalize. If something needs the user's attention, surface it in the final summary only — not midway through the run.

## Workflow (6 stages)

Execute stages in order. Read the matching reference file before each stage. Do not skip reference files — they contain exact commands.

| # | Stage | Reference |
|---|---|---|
| 0 | Entry alignment (OS detect, plan, confirm) | `SKILL.md` (this file, section below) |
| 1 | Base tools (Node / Git / jq / curl) | `references/02-install-base.md` |
| 2 | Agent Skills (kepano + axtonliu) | `references/03-install-skills.md` |
| 3 | Obsidian app + Web Clipper | `references/04-install-obsidian.md` |
| 4 | Create wiki from template | `references/05-create-wiki.md` |
| 5 | Obsidian plugins + Minimal theme | `references/06-install-plugins.md` |
| 6 | Finalize (git, summary) | `references/07-finalize.md` |

Detection rules shared across stages: see `references/01-detect-tools.md`.

## Stage 0: Entry alignment

1. Run `uname -s` to detect OS. Record as `OS` = macos / linux / windows.
2. **Parameter hint** (only when triggered by bare `/llm-wiki-starter` with NO parameters): print ONE concise line listing available flags before anything else, so the user discovers them. List `--bash` first since power users invoke it most often:

   ```
   Parameters (optional): --bash  --name <wiki-name>  --lang <en|zh>  --dir <path>  --only-tools  --only-wiki  --only-obsidian
   No params given — continuing interactively.
   ```

   Skip this hint if: (a) the user passed any parameter, OR (b) triggered via natural language (not the slash command).

3. Parse any CLI parameters passed with `/llm-wiki-starter`. Remember them for later stages. If an unknown flag appears, print ONE line: `Unknown parameter: <flag>. Valid: --bash, --name, --lang, --dir, --only-tools, --only-wiki, --only-obsidian. Ignoring.` and continue. The three `--only-*` flags are mutually exclusive — if more than one is passed, keep the last and warn `Conflicting --only-* flags; using <last>`.

4. **If `--bash` was passed: short-circuit to bash mode.** Do NOT read any other reference files, do NOT run the 6-stage SOP. Instead, run a single bash command that pipes the upstream `install.sh` into bash, forwarding the other parameters:

   ```bash
   curl -fsSL https://raw.githubusercontent.com/eleven-net-cn/llm-wiki-starter/main/install.sh \
     | bash -s -- --yes <forwarded params>
   ```

   Forward only parameters install.sh understands: `--name`, `--lang`, `--dir`, `--only-tools`, `--only-wiki`, `--only-obsidian`. Always append `--yes` so install.sh runs non-interactively.

   Example: `/llm-wiki-starter --bash --name foo --lang zh` → runs `curl ... | bash -s -- --yes --name foo --lang zh`.

   After install.sh exits, relay its exit status (success / failure) in ONE line. Do NOT layer a Skill-style summary on top — install.sh prints its own summary already.

5. Go directly to Stage 1. Do NOT ask "Proceed?" or any other confirmation — the user's request to create a wiki IS the confirmation. Global principle #8 (Act, don't narrate) applies to trigger paths too.

**Reminder**: even if the user has run this Skill before and has an existing wiki on disk, the goal of this run is to create a NEW wiki. Stage 4 will prompt for a fresh name/dir. Do not interpret a prior wiki as "the work is already done."

## Parameter reference

Names mirror `install.sh` so the two install paths stay aligned. Listed in suggested-display order (most commonly used first).

| Flag | Default | Behavior |
|---|---|---|
| `--bash` | (off) | **Bypass the 6-stage SOP**. Execute upstream `install.sh` in one shell call (non-interactive, `--yes`) and forward the other flags. Minimizes AI token cost. The AI reads only SKILL.md Stage 0 step 4, no other reference files. |
| `--name <wiki-name>` | (prompt) | Wiki directory name. Collision → re-prompt. |
| `--lang <en\|zh>` | `en` (or prompt) | Language overlay for template. |
| `--dir <path>` | `$(pwd)` (or prompt) | Parent directory; wiki created at `<dir>/<name>`. |
| `--only-tools` | (off) | Run Stages 1-3 only (base tools / Agent Skills / Obsidian app). Skip Stages 4-6 — no wiki created. |
| `--only-wiki` | (off) | Skip Stages 1-3 (assumes tools already installed). Run Stage 4 (create wiki) + Stage 5 (plugins/theme) + Stage 6 (finalize). |
| `--only-obsidian` | (off) | Skip Stages 1-4. Run Stage 5 only (install plugins + theme into an existing vault) + a brief Stage 6 summary. Requires `--dir` pointing at a vault containing `CLAUDE.md`. |

Then proceed to stage 1 (or skip ahead per the `--only-*` flag in effect).

## Canvas constraint (already encoded in template)

The template's `AGENTS.md` instructs future AI sessions inside the new vault to use `obsidian-canvas-creator` (axtonliu/visual-skills) for `.canvas` creation, not `json-canvas` (which kepano/obsidian-skills bundles). You don't need to repeat this in the user-facing finalize summary — that line is for AI coordination, and AGENTS.md already carries it into the vault.
