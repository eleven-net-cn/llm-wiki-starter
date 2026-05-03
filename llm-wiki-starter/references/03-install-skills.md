# Stage 2: Install Agent Skills

Two packages to install. Both use the vercel-labs/skills CLI via `npx` (no global skills CLI install needed).

## kepano/obsidian-skills

**Install:**

```bash
npx -y skills add kepano/obsidian-skills -g -y
```

**Detect before / verify after** (per `references/01-detect-tools.md` — `~/.agents/` preferred over `~/.claude/`):

```bash
for d in \
  "$HOME/.agents/skills/obsidian-markdown" \
  "$HOME/.agents/skills/obsidian-cli" \
  "$HOME/.claude/skills/obsidian-markdown" \
  "$HOME/.claude/skills/obsidian-cli"; do
  [[ -d "$d" ]] && { echo "✓ kepano/obsidian-skills (found at $d)"; installed=true; break; }
done
```

## axtonliu/axton-obsidian-visual-skills

**Install:**

```bash
npx -y skills add axtonliu/axton-obsidian-visual-skills -g -y
```

**Detect:**

```bash
for d in \
  "$HOME/.agents/skills/excalidraw-diagram" \
  "$HOME/.agents/skills/obsidian-canvas-creator" \
  "$HOME/.claude/skills/excalidraw-diagram" \
  "$HOME/.claude/skills/obsidian-canvas-creator" \
  "$HOME/.claude/plugins/marketplaces/axton-obsidian-visual-skills/excalidraw-diagram"; do
  [[ -d "$d" ]] && { echo "✓ axtonliu/visual-skills (found at $d)"; installed=true; break; }
done
```

## Canvas operations constraint (MUST tell the user)

`kepano/obsidian-skills` bundles 5 skills: `defuddle`, `json-canvas`, `obsidian-bases`, `obsidian-cli`, `obsidian-markdown`.

**json-canvas is installed but should not be used.** All Canvas creation and editing must use `obsidian-canvas-creator` (from axtonliu/visual-skills).

Do not delete the `json-canvas` directory — `skills update` may pull it back. Instead, the Stage 6 summary and the generated wiki's CLAUDE.md / AGENTS.md (already present in the template) should note this constraint.

## Failure handling

If either `npx` install fails (network, registry):

- Record to manual-install list:
  - `kepano/obsidian-skills: npx -y skills add kepano/obsidian-skills -g -y`
  - `axtonliu/visual-skills: npx -y skills add axtonliu/axton-obsidian-visual-skills -g -y`
- Continue to Stage 3; skills are not critical-path for creating the wiki.
