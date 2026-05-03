# Stage 5: Install Obsidian plugins + Minimal theme

Read `skills/llm-wiki-starter/assets/plugin-manifest.json`. It defines:

- `core[]` — 9 plugins (llm-wiki functionality)
- `ux[]` — 8 plugins (editing experience)
- `theme` — Minimal theme

## Plugin download

For each entry `{repo, id, desc, requires?}`:

1. **Skip conditions:**
   - If `<wiki>/.obsidian/plugins/<id>/manifest.json` already exists and is non-empty: print `✓ <id> (exists)` and skip.
   - If `requires: "git"` and Git was not installed successfully: print `- <id> (skipped: no git)` and skip. This applies to `obsidian-git`.

2. **Download three files** from `https://github.com/<repo>/releases/latest/download/`:
   - `main.js` (required)
   - `manifest.json` (required)
   - `styles.css` (optional)

Use curl with 30-second timeout:

````bash
curl -fsSL --max-time 30 "$base_url/main.js" -o "$plugin_dir/main.js"
curl -fsSL --max-time 30 "$base_url/manifest.json" -o "$plugin_dir/manifest.json"
````

3. **styles.css handling** (optional):

````bash
css_status=$(curl -sSL --max-time 30 -w '%{http_code}' -o "$plugin_dir/styles.css" "$base_url/styles.css" 2>/dev/null || echo "000")
if [[ "$css_status" != "200" ]]; then
  rm -f "$plugin_dir/styles.css"
fi
````

Log based on status:
- 200 → keep silently
- 404 → silent (plugin has no CSS)
- anything else (timeout / 5xx) → `⚠ <id>: styles.css not downloaded (HTTP <status>)`

4. **Record installed** id to a list.

## Plugin-specific config

After all plugins installed, for `custom-sort` specifically:

If `<wiki>/.obsidian/plugins/custom-sort/` exists but lacks `data.json`, create it:

````json
{"suspended":false,"statusBarEntryEnabled":true,"notificationsEnabled":true,"customSortContextSubmenu":true}
````

## Theme: Minimal

From `plugin-manifest.json`, `theme.repo` = `kepano/obsidian-minimal`, `theme.id` = `Minimal`.

If `<wiki>/.obsidian/themes/Minimal/` does not exist:

````bash
theme_dir="<wiki>/.obsidian/themes/Minimal"
mkdir -p "$theme_dir"
curl -fsSL --max-time 30 "https://github.com/kepano/obsidian-minimal/releases/latest/download/manifest.json" -o "$theme_dir/manifest.json"
curl -fsSL --max-time 30 "https://github.com/kepano/obsidian-minimal/releases/latest/download/theme.css" -o "$theme_dir/theme.css"
````

## Write community-plugins.json

After all plugins installed, write `<wiki>/.obsidian/community-plugins.json`:

````json
["claudian", "dataview", "templater-obsidian", ...]
````

— an array of all successfully installed plugin ids, in the order they were installed.

## Write appearance.json

If `<wiki>/.obsidian/appearance.json` does not exist, create it:

````json
{"cssTheme": "Minimal"}
````

If it exists, merge `cssTheme: Minimal` into it (do not overwrite unrelated keys).

## Disable Safe Mode (critical — or plugins stay inert)

Obsidian's Safe Mode is ON by default in a fresh vault. With Safe Mode on, `community-plugins.json` is recorded but no plugin actually runs — the user would have to go to Settings → Community plugins and toggle off Safe Mode manually.

To enable plugins out-of-the-box, merge `"communityPluginsEnabled": true` into `<wiki>/.obsidian/app.json`:

- If `app.json` does not exist: create with `{"communityPluginsEnabled": true}`.
- If it exists: parse JSON, set `.communityPluginsEnabled = true`, write back. Do not clobber other keys (the template ships with `attachmentFolderPath`, `defaultViewMode`, etc. — preserve them).

Example using `jq`:

````bash
app_json="$wiki_dir/.obsidian/app.json"
if [[ -f "$app_json" ]]; then
  tmp=$(mktemp)
  jq '. + {communityPluginsEnabled: true}' "$app_json" > "$tmp" && mv "$tmp" "$app_json"
else
  echo '{"communityPluginsEnabled": true}' > "$app_json"
fi
````

Without `jq`, use `python3 -c "..."` to do the same read-modify-write.
