# Stage 4: Create wiki from template

**This stage is the workflow's purpose.** Every invocation creates a NEW wiki. Do NOT silently skip this stage just because some previously-created wiki already exists on disk — always prompt the user for the new wiki's name / lang / dir.

The only exception is the `--only-obsidian` flag, which means "configure Obsidian plugins/theme in an existing vault" — Stage 4 is skipped entirely and Stage 5 runs against `--dir`.

## Gather inputs

Using host CLI native prompts. Skip any prompt whose value was already supplied via `/llm-wiki-starter` parameters (`--name`, `--lang`, `--dir`).

1. **Wiki name** — used for directory name and placeholder replacement. Suggest a default that does NOT collide with an existing directory under the chosen parent (e.g. if `~/Documents/CODE/my-wiki` exists, suggest `my-wiki-2` or `<topic>-wiki`).
2. **Language** (`en` | `zh`, default `en`) — picks template overlay.
3. **Parent directory** (default `$(pwd)`) — wiki will be created at `<parent>/<name>`.

## Validate target

Compute `target = <parent>/<name>`. Check for collisions:

- **`target` does not exist** → proceed to download template (this is the happy path).
- **`target` exists and contains `CLAUDE.md`** → it is already an llm-wiki vault. Tell the user: "目录 `<target>` 已经是一个 wiki，请输入一个不同的名字" / "Directory `<target>` is already a wiki — please enter a different name", then re-prompt for `name` (and/or `parent`). Do NOT silently reuse the existing wiki and do NOT proceed to Stage 5 against it.
- **`target` exists but is not a wiki** (no `CLAUDE.md`) → tell the user the directory exists, ask for a different name or parent.

Loop the prompt + validation until the target is a fresh path. Only then proceed to download.

## Download template tarball

```bash
TMPDIR=$(mktemp -d)
trap "rm -rf $TMPDIR" EXIT

curl -fsSL https://github.com/eleven-net-cn/llm-wiki-starter/archive/refs/heads/main.tar.gz \
  -o "$TMPDIR/repo.tar.gz"

tar -xzf "$TMPDIR/repo.tar.gz" -C "$TMPDIR"

TEMPLATE_ROOT=$(find "$TMPDIR" -maxdepth 1 -type d -name 'llm-wiki-starter-*' | head -1)/template
```

Verify `TEMPLATE_ROOT/base` and `TEMPLATE_ROOT/<lang>` directories exist.

## Layered copy

```bash
WIKI_DIR="<parent>/<name>"
mkdir -p "$WIKI_DIR"

# Layer 1: shared base (.gitignore, canvas/, root sortspec)
cp -a "$TEMPLATE_ROOT/base/." "$WIKI_DIR/"

# Layer 2: language overlay (CLAUDE.md, AGENTS.md, README.md, raw/, wiki/)
cp -a "$TEMPLATE_ROOT/$LANG/." "$WIKI_DIR/"
```

Create empty directories git does not track. For `lang=zh`:

```bash
mkdir -p "$WIKI_DIR"/{wiki/assets/excalidraw,canvas,raw/收件箱,raw/assets,wiki/概念,wiki/资料摘要,wiki/综合分析,wiki/归档}
```

For `lang=en`:

```bash
mkdir -p "$WIKI_DIR"/{wiki/assets/excalidraw,canvas,raw/inbox,raw/assets,wiki/concepts,wiki/summaries,wiki/synthesis,wiki/archived}
```

## Placeholder replacement

Replace `<Wiki Name>`, `<wiki-name>`, and `{{date}}` in known files.

Files to patch (exist only in some languages — check each):

- `CLAUDE.md`, `AGENTS.md`, `README.md`
- `wiki/知识库概览.md`, `wiki/Wiki 目录.md`, `wiki/操作日志.md` (zh)
- `wiki/Overview.md`, `wiki/Index.md`, `wiki/Changelog.md` (en)

On macOS / Linux (GNU sed or BSD sed):

```bash
TODAY=$(date +%Y-%m-%d)
for f in "${FILES[@]}"; do
  [[ -f "$WIKI_DIR/$f" ]] || continue
  if [[ "$OS" == "macos" ]]; then
    sed -i '' "s/<Wiki Name>/$NAME/g; s/<wiki-name>/$NAME/g; s/{{date}}/$TODAY/g" "$WIKI_DIR/$f"
  else
    sed -i "s/<Wiki Name>/$NAME/g; s/<wiki-name>/$NAME/g; s/{{date}}/$TODAY/g" "$WIKI_DIR/$f"
  fi
done
```

On Windows native (cmd / PowerShell without sed), use PowerShell:

```powershell
$today = Get-Date -Format "yyyy-MM-dd"
foreach ($f in $files) {
  if (Test-Path "$wikiDir\$f") {
    (Get-Content "$wikiDir\$f") `
      -replace '<Wiki Name>', $name `
      -replace '<wiki-name>', $name `
      -replace '\{\{date\}\}', $today |
    Set-Content -Encoding UTF8 "$wikiDir\$f"
  }
}
```

## Verify

After Stage 4:

- `$WIKI_DIR/CLAUDE.md` exists and contains `$NAME` (not `<Wiki Name>`)
- `$WIKI_DIR/.gitignore` exists (from base layer)
- `$WIKI_DIR/raw/` and `$WIKI_DIR/wiki/` directories populated

Proceed to Stage 5.
