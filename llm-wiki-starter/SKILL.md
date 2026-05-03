---
name: llm-wiki-starter
description: Scaffold an LLM Wiki knowledge base (Andrej Karpathy pattern) — detect and install base tools, Obsidian + 17 plugins + Minimal theme + shortcuts, Agent Skills, check for browser Web Clipper, and create the vault from the official template. Use when user says 创建 llm-wiki 知识库, 创建知识库, create llm wiki, scaffold llm wiki, set up knowledge base with Obsidian, or invokes /llm-wiki-starter.
---

# llm-wiki-starter

Guide the user through scaffolding an LLM Wiki knowledge base end-to-end: detect what's already installed, install what's missing across OS/package-manager combinations, create the vault from the official template, and configure Obsidian.

The user is already running an AI CLI to invoke this Skill — do NOT prompt them to install another AI agent.

## When to use

- Natural language: user says 创建 llm-wiki 知识库, 创建知识库, create llm wiki, scaffold llm wiki, set up knowledge base.
- Explicit command: `/llm-wiki-starter` (optionally with `--name <wiki-name>`, `--lang <en|zh>`, `--dir <path>`, `--skip-tools`, `--only-obsidian`).

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
2. Unless the user invoked `/llm-wiki-starter` (explicit command = confirmed intent), ask: "Proceed?" Accept yes/proceed/继续/ok as confirmation. Do NOT pre-announce the upcoming stages — global principle #8.
3. Parse any CLI parameters passed with `/llm-wiki-starter`. Remember them for later stages.

**Reminder**: even if the user has run this Skill before and has an existing wiki on disk, the goal of this run is to create a NEW wiki. Stage 4 will prompt for a fresh name/dir. Do not interpret a prior wiki as "the work is already done."

Then proceed to stage 1.

## Canvas constraint (already encoded in template)

The template's `AGENTS.md` instructs future AI sessions inside the new vault to use `obsidian-canvas-creator` (axtonliu/visual-skills) for `.canvas` creation, not `json-canvas` (which kepano/obsidian-skills bundles). You don't need to repeat this in the user-facing finalize summary — that line is for AI coordination, and AGENTS.md already carries it into the vault.
