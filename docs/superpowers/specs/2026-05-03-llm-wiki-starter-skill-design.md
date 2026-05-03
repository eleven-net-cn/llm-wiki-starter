# llm-wiki-starter Skill 设计文档

## Context

`llm-wiki-starter` 仓库当前提供一条 `curl | bash install.sh` 命令一键创建 Andrej Karpathy 风格的 LLM Wiki 知识库。该路径在 macOS / Linux / Git Bash + WSL2 工作良好，但**不能跨过"必须有 bash 环境"这道坎**——Windows cmd / PowerShell 用户跑不动；脚本 OS 分支也无法覆盖所有发行版（zypper / apk / 边缘 Linux）；脚本需要随 OS / 包管理器演化持续维护降级链。

本设计为 `llm-wiki-starter` 仓库新增**第二条创建路径**：一个名为 `llm-wiki-starter` 的 Skill，由 AI Agent（Claude Code / Codex / Copilot CLI / Gemini CLI / OpenCode 等）原生执行。Skill 用知识库手册的形式描述每一步的检测与执行规则，由 Agent 用其原生工具（Bash / Read / Write / Edit）逐步落地。优势：

- **不受 OS / 包管理器限制**：Agent 在 Windows 原生 cmd 也能直接调 winget 而不依赖 bash
- **可反复使用**：Skill 装一次后任何对话里说"创建 llm-wiki 知识库"都能触发
- **更大的用户自由度**：Agent 可在执行中根据用户即时反馈调整策略
- **install.sh 不消失**：作为传统一键路径继续保留，两条路径共存、共用同一份插件清单数据

预期产出：用户在任何安装了 AI CLI 的环境里执行
```bash
npx -y skills add eleven-net-cn/llm-wiki-starter -g -y
```
之后说"创建 llm-wiki 知识库"，AI 即按 Skill 引导完成全流程。

---

## 1. 仓库布局

```
llm-wiki-starter/                              # 仓库根
├── skills/
│   └── llm-wiki-starter/                      # 实际 Skill 实体
│       ├── SKILL.md                           # frontmatter + 工作流入口
│       ├── references/                        # 分章节知识（避免 SKILL.md 过长）
│       │   ├── 01-detect-tools.md             # 已装/缺失检测协议
│       │   ├── 02-install-base.md             # Node / Git / jq
│       │   ├── 03-install-ai-agents.md        # 5 个 AI CLI 选单与安装命令
│       │   ├── 04-install-obsidian.md         # Obsidian 应用 + Web Clipper
│       │   ├── 05-install-plugins.md          # 17 个插件 + Minimal 主题下载与配置
│       │   ├── 06-install-skills.md           # kepano + axtonliu Skills，json-canvas 软禁用约束
│       │   ├── 07-create-wiki.md              # tarball 下载 + 分层拷贝 + 占位符替换
│       │   └── 08-finalize.md                 # community-plugins.json、custom-sort、git init、收尾摘要
│       └── assets/
│           └── plugin-manifest.json           # 17 个插件 + 主题的唯一真源数据
├── install.sh                                 # 保留并改造为读 plugin-manifest.json
├── template/                                  # 保留（Skill 走 tarball 拿这里的内容）
├── docs/superpowers/specs/                    # 本设计文档
├── README.md / README.zh-CN.md                # 新增"两种安装方式"说明
└── ...（原有文件不变）
```

**布局风险与应对**：vercel-labs/skills CLI 的默认约定是"仓库根下的子目录 = Skill"（参见 kepano/obsidian-skills、axtonliu/axton-obsidian-visual-skills）。把 Skill 放进 `skills/` 父目录是嵌套结构，CLI 可能扫不到。

**实施阶段必做兼容性验证**：本地用 `npx -y skills add eleven-net-cn/llm-wiki-starter -g -y` 试装。若失败：

- 退化方案 A：把 `skills/llm-wiki-starter/` 移到仓库根 `llm-wiki-starter/`（与 vercel-labs 约定一致）
- 退化方案 B：仓库根 `llm-wiki-starter/` 与 `skills/llm-wiki-starter/` 双份同步（用一份做 source、另一份用 git pre-commit hook 镜像）

设计仅在验证通过后保留首选布局。

---

## 2. SKILL.md frontmatter 与触发协议

```yaml
---
name: llm-wiki-starter
description: Scaffold an LLM Wiki knowledge base (Andrej Karpathy pattern) — install base tools, AI agents, Obsidian + plugins + theme + shortcuts, browser Web Clipper, and create the vault from the official template. Use when user says 创建 llm-wiki 知识库, 创建知识库, create llm wiki, scaffold llm wiki, set up knowledge base with Obsidian + AI agent.
---
```

- `name`：kebab-case，与仓库名一致，符合 skills CLI 规范
- `description`：触发条件的唯一载体；中英关键词并列以覆盖中英文用户
- 不引入 MCP 服务器（vercel-labs/skills 装的 Skill 默认不挂 MCP）

**触发路径**：

1. **自然语言**：Agent 看到关键词（创建 llm-wiki 知识库 / 创建知识库 / create llm wiki / scaffold llm wiki / set up knowledge base）自动加载
2. **显式命令**：`/llm-wiki-starter` 直接调起，跳过"是否要创建"的确认
3. **可选参数**（命令模式可带）：`--name <wiki-name>` `--lang <en|zh>` `--dir <path>` `--skip-tools` `--only-obsidian`，提供则跳过对应交互

---

## 3. 工作流（7 阶段 SOP）

每阶段在 `references/` 下有独立文件，Agent 按顺序读、按顺序执行。每阶段开头都先 detect → skip-or-install。

| # | 阶段 | reference 文件 | Agent 行为 | 交互点 |
|---|---|---|---|---|
| 0 | 入口对齐 | `SKILL.md` 主体 | `uname -s` 判 OS；打印计划；如无显式命令则确认继续 | 可中断 |
| 1 | 基础工具 | `02-install-base.md` | 检测 + 装 Node / Git / jq / curl；按 OS 分支用 brew / apt / dnf / pacman / winget / choco / scoop | 装不上 → 记录手装清单 |
| 2 | AI 工具 | `03-install-ai-agents.md` | 多选呈现 5 个 AI CLI；按用户勾选执行 | 多选确认 |
| 3 | Agent Skills | `06-install-skills.md` | 检测 + 装 kepano + axtonliu；写明 json-canvas 软禁用约束 | 自动 |
| 4 | Obsidian 本体 + Web Clipper | `04-install-obsidian.md` | 装 Obsidian；检测浏览器 Clipper 扩展目录，未装打官网链接 | Clipper 手装 |
| 5 | 创建 Wiki | `07-create-wiki.md` | 询问 wiki 名/目录/语言；curl tarball 解压 → 分层拷贝 → 占位符替换 | 3 个输入 |
| 6 | 配置 Obsidian | `05-install-plugins.md` + `08-finalize.md` | 读 `plugin-manifest.json`；逐个下载插件 + Minimal 主题；写 `community-plugins.json` 与 `custom-sort/data.json` | 失败给手装命令 |
| 7 | 收尾 | `08-finalize.md` | `git init` + 首次 commit；打印结构化摘要（已装 / 跳过 / 手装清单 / Quick start） | 结束 |

**全流程硬性原则**（写在 `SKILL.md` 顶部、每个 reference 文件顶部各重申一次）：

1. **每步先检测再执行**：打 ✓（已装）/ ↓（正在装）/ ⚠（失败，给手装命令），永不重装
2. **失败不阻塞**：单项失败只记录到手装清单，继续后续阶段
3. **OS 判断**：`uname -s` → macOS / Linux / Windows；Windows 进一步判 cmd 还是 Git Bash（`echo %OS%` vs `uname` 的可用性）
4. **不假设特定 UI**：让 Agent 用其所在 CLI 的原生交互方式（Claude Code 的 AskUserQuestion / Codex 的对话确认 / 其他 CLI 的 prompt）
5. **可中断可续跑**：全程幂等，重跑从任何阶段开始都不破坏已有状态
6. **不做配置/登录提示**：装完 AI 工具不提示 `claude login` / API key 配置；用户自己懂

---

## 4. AI 工具与 Agent Skills 安装矩阵

### AI 工具（阶段 2）

5 项默认展示、Claude Code 预选、其他用户可勾。检测命令统一 `command -v`：

| AI CLI | macOS | Linux | Windows | 检测 |
|---|---|---|---|---|
| Claude Code（默认勾选） | `npm i -g @anthropic-ai/claude-code` | 同 | 同（需 npm） | `command -v claude` |
| Codex CLI | `npm i -g @openai/codex` | 同 | 同 | `command -v codex` |
| GitHub Copilot CLI | `gh extension install github/gh-copilot`（先确保 `gh` 已装） | 同 | 同 | `gh extension list \| grep gh-copilot` |
| Gemini CLI | `npm i -g @google/gemini-cli` | 同 | 同 | `command -v gemini` |
| OpenCode | `curl -fsSL https://opencode.ai/install \| bash` | 同 | WSL2/Git Bash 同；原生 cmd 提示官网 | `command -v opencode` |

`gh` 缺失时先按 OS 装 `gh`：macOS `brew install gh` / Linux `apt install gh` / Windows `winget install GitHub.cli`。

### Agent Skills（阶段 3）

| Skill 包 | 安装命令 | 检测路径（按优先级） |
|---|---|---|
| kepano/obsidian-skills | `npx -y skills add kepano/obsidian-skills -g -y` | 1. `~/.agents/skills/obsidian-markdown` 2. `~/.agents/skills/obsidian-cli` 3. `~/.claude/skills/obsidian-markdown` 4. `~/.claude/skills/obsidian-cli` |
| axtonliu/axton-obsidian-visual-skills | `npx -y skills add axtonliu/axton-obsidian-visual-skills -g -y` | 1. `~/.agents/skills/excalidraw-diagram` 2. `~/.agents/skills/obsidian-canvas-creator` 3. `~/.claude/skills/excalidraw-diagram` 4. `~/.claude/skills/obsidian-canvas-creator` 5. `~/.claude/plugins/marketplaces/axton-obsidian-visual-skills/excalidraw-diagram` |

任一路径存在即判定已装。**`~/.agents/` 优先于 `~/.claude/`**。

**json-canvas 软禁用**：装完 kepano/obsidian-skills 会带入 5 个 Skill（defuddle / json-canvas / obsidian-bases / obsidian-cli / obsidian-markdown）。本 Skill 在 `06-install-skills.md` 末尾与 `08-finalize.md` 收尾摘要里硬性写明：

> Canvas 创建/编辑一律使用 `axtonliu/axton-obsidian-visual-skills` 下的 `obsidian-canvas-creator`，不要触发 `json-canvas`。

不删除 json-canvas 目录（避免与未来 `skills update` 冲突），只在 Skill 文档层面给 AI 下达硬性约束。

---

## 5. Obsidian 插件清单真源（DRY）

`install.sh:893-932` 当前硬编码 17 条 `repo|id`。Skill 不再硬编码，而是与 install.sh **共用同一份 JSON**。

### `skills/llm-wiki-starter/assets/plugin-manifest.json`

```json
{
  "core": [
    {"repo": "YishenTu/claudian", "id": "claudian", "desc": "AI agent in vault"},
    {"repo": "blacksmithgu/obsidian-dataview", "id": "dataview", "desc": "Query and display data from notes"},
    {"repo": "SilentVoid13/Templater", "id": "templater-obsidian", "desc": "Templates and automation"},
    {"repo": "Vinzent03/obsidian-git", "id": "obsidian-git", "desc": "Git version control", "requires": "git"},
    {"repo": "platers/obsidian-linter", "id": "obsidian-linter", "desc": "Markdown linting"},
    {"repo": "pjeby/tag-wrangler", "id": "tag-wrangler", "desc": "Tag management"},
    {"repo": "TfTHacker/obsidian42-strange-new-worlds", "id": "obsidian42-strange-new-worlds", "desc": "Link context"},
    {"repo": "mirnovov/obsidian-homepage", "id": "homepage", "desc": "Dashboard/homepage"},
    {"repo": "SebastianMC/obsidian-custom-sort", "id": "custom-sort", "desc": "Custom file sorting"}
  ],
  "ux": [
    {"repo": "scambier/obsidian-omnisearch", "id": "omnisearch", "desc": "Fuzzy search across vault"},
    {"repo": "darlal/obsidian-switcher-plus", "id": "darlal-switcher-plus", "desc": "Quick switcher with headings"},
    {"repo": "kepano/obsidian-minimal-settings", "id": "obsidian-minimal-settings", "desc": "Minimal theme settings"},
    {"repo": "kepano/obsidian-hider", "id": "obsidian-hider", "desc": "Hide UI elements"},
    {"repo": "PKM-er/obsidian-editing-toolbar", "id": "editing-toolbar", "desc": "Word-like toolbar + F11"},
    {"repo": "zsviczian/obsidian-excalidraw-plugin", "id": "obsidian-excalidraw-plugin", "desc": "Hand-drawn diagrams"},
    {"repo": "guopenghui/obsidian-quiet-outline", "id": "obsidian-quiet-outline", "desc": "Enhanced outline"},
    {"repo": "yonatan-reicher/obsidian-open-in-terminal", "id": "open-in-terminal", "desc": "Open vault in terminal"}
  ],
  "theme": {"repo": "kepano/obsidian-minimal", "id": "Minimal"}
}
```

### install.sh 改造

把 `install.sh:893-914` 的硬编码数组改为读 JSON（伪代码）：

```bash
local manifest="$wiki_dir/.tmp-manifest.json"  # 或从 skills/.../assets 复制
core_plugins=()
while IFS= read -r line; do
  core_plugins+=("$line")
done < <(jq -r '.core[] | "\(.repo)|\(.id)"' "$manifest")

ux_plugins=()
while IFS= read -r line; do
  ux_plugins+=("$line")
done < <(jq -r '.ux[] | "\(.repo)|\(.id)"' "$manifest")
```

依赖：`jq`（install.sh 已有 `install_jq` 与 Python fallback `install.sh:486-540`）。

### Skill 侧使用

`05-install-plugins.md` 写明：

1. 读 `assets/plugin-manifest.json`
2. 对每个 `core` / `ux` 条目：
   - 检测 `<wiki>/.obsidian/plugins/<id>/` 已存在 → ✓ 跳过
   - 否则按 `https://github.com/<repo>/releases/latest/download/{main.js,manifest.json,styles.css}` 下载
   - styles.css HTTP 状态码处理：200 保留 / 404 静默删 / 其他打 ⚠ 警告（与 `install.sh:865-878` 同策略）
3. `custom-sort` 装完后写 `data.json`：`{"suspended":false,"statusBarEntryEnabled":true,...}`
4. 主题：从 `https://github.com/kepano/obsidian-minimal/releases/latest/download/` 下 `manifest.json` + `theme.css` 到 `<wiki>/.obsidian/themes/Minimal/`
5. 写 `<wiki>/.obsidian/community-plugins.json`：所有成功安装的 id 列表
6. 写 `<wiki>/.obsidian/appearance.json`：主题 = Minimal（如未存在）

**改一个插件 = 改一处 JSON**，install.sh 与 Skill 自动同步。

---

## 6. 模板获取与 Wiki 创建

阶段 5（`07-create-wiki.md`）按 install.sh:737-815 同构逻辑，但用 curl tarball 替代 git clone（与拾一确认）：

```bash
TMPDIR=$(mktemp -d)
curl -fsSL https://github.com/eleven-net-cn/llm-wiki-starter/archive/refs/heads/main.tar.gz \
  -o "$TMPDIR/repo.tar.gz"
tar -xzf "$TMPDIR/repo.tar.gz" -C "$TMPDIR"
TEMPLATE="$(find "$TMPDIR" -maxdepth 1 -type d -name 'llm-wiki-starter*')/template"

mkdir -p "$WIKI_DIR"
cp -a "$TEMPLATE/base/." "$WIKI_DIR/"           # Layer 1: 公共底
cp -a "$TEMPLATE/$LANG/." "$WIKI_DIR/"          # Layer 2: 语言覆盖

# 占位符替换
TODAY=$(date +%Y-%m-%d)
for f in CLAUDE.md AGENTS.md README.md wiki/*.md; do
  [[ -f "$WIKI_DIR/$f" ]] || continue
  sed -i.bak "s/<Wiki Name>/$NAME/g; s/<wiki-name>/$NAME/g; s/{{date}}/$TODAY/g" "$WIKI_DIR/$f"
  rm -f "$WIKI_DIR/$f.bak"
done

rm -rf "$TMPDIR"
```

**Windows 原生 cmd 适配**：`curl` Windows 10+ 自带；`tar` Windows 10+ 自带；`sed` 不自带 → Skill 在 Windows 分支让 Agent 用 PowerShell `(Get-Content X) -replace ... | Set-Content X` 完成占位符替换。

---

## 7. Web Clipper 检测

阶段 4 末尾，按 OS + 浏览器枚举常见扩展安装目录（Obsidian Web Clipper Chrome 扩展 ID `cnjifjpddelmedmihgijeibhnjfabmlc`）：

| OS | Chrome | Edge | Firefox |
|---|---|---|---|
| macOS | `~/Library/Application Support/Google/Chrome/Default/Extensions/cnjifjpddelmedmihgijeibhnjfabmlc/` | `~/Library/Application Support/Microsoft Edge/Default/Extensions/...` | `~/Library/Application Support/Firefox/Profiles/*/extensions/` |
| Linux | `~/.config/google-chrome/Default/Extensions/...` | `~/.config/microsoft-edge/Default/Extensions/...` | `~/.mozilla/firefox/*/extensions/` |
| Windows | `%LOCALAPPDATA%\Google\Chrome\User Data\Default\Extensions\...` | `%LOCALAPPDATA%\Microsoft\Edge\User Data\Default\Extensions\...` | `%APPDATA%\Mozilla\Firefox\Profiles\*\extensions\` |

任一路径存在 → ✓ 已装；都不存在 → 打印 `https://obsidian.md/clip` 并提示用户手装。不阻塞流程。

---

## 8. 收尾摘要（阶段 7）

```
✓ Wiki created: ~/Documents/my-kb (lang: zh)

Installed:
  ✓ Claude Code (2.x.x)
  ✓ Node.js (v20.x)
  ✓ Obsidian
  ✓ kepano/obsidian-skills
    ⚠ Canvas 操作请使用 obsidian-canvas-creator,不要使用 json-canvas
  ✓ axtonliu/visual-skills
  ✓ 17 Obsidian plugins + Minimal theme

Skipped (already installed):
  - Git (2.40)

Manual install required:
  ⚠ Web Clipper: https://obsidian.md/clip (install in your browser)
  ⚠ Codex CLI: npm i -g @openai/codex (network failed)

Quick start:
  1. cd ~/Documents/my-kb
  2. open -a Obsidian .       # macOS
     obsidian .                # Linux
     start obsidian .          # Windows
  3. claude                    # 启动 AI agent
```

---

## 9. README 改造

`README.md` 与 `README.zh-CN.md` 的 `## Installation` 段顶部新增"两种安装方式"子段：

```markdown
## Installation

There are two ways to scaffold a wiki:

### Option A — Skill-based (recommended for AI Agent users)

Install the Skill once via npx (no need to install skills CLI globally):

```bash
npx -y skills add eleven-net-cn/llm-wiki-starter -g -y
```

Then in any AI CLI (Claude Code / Codex / Copilot / Gemini / OpenCode), say
"创建 llm-wiki 知识库" / "create llm wiki", or run `/llm-wiki-starter`.

The AI agent will guide you through detection, installation, and wiki creation
with full freedom to adapt to your OS / package manager.

### Option B — One-shot bash script

[原有的 curl | bash 段落保留不变]
```

中文版 README 对应位置加同结构段落。

---

## 10. 关键文件改动清单

| 路径 | 改动 |
|---|---|
| `skills/llm-wiki-starter/SKILL.md` | **新增**：frontmatter + 7 阶段 SOP 入口 + 全局原则 |
| `skills/llm-wiki-starter/references/01-detect-tools.md` | **新增**：检测协议 |
| `skills/llm-wiki-starter/references/02-install-base.md` | **新增**：Node / Git / jq 安装矩阵 |
| `skills/llm-wiki-starter/references/03-install-ai-agents.md` | **新增**：5 个 AI CLI 多选 |
| `skills/llm-wiki-starter/references/04-install-obsidian.md` | **新增**：Obsidian + Web Clipper |
| `skills/llm-wiki-starter/references/05-install-plugins.md` | **新增**：插件 + 主题安装规则 |
| `skills/llm-wiki-starter/references/06-install-skills.md` | **新增**：kepano + axtonliu，json-canvas 软禁用约束 |
| `skills/llm-wiki-starter/references/07-create-wiki.md` | **新增**：tarball 拷贝 + 占位符替换 |
| `skills/llm-wiki-starter/references/08-finalize.md` | **新增**：community-plugins.json、git init、收尾 |
| `skills/llm-wiki-starter/assets/plugin-manifest.json` | **新增**：17 插件 + 主题真源 |
| `install.sh:232-244` | **改**：检测路径 `~/.agents` 优先于 `~/.claude` |
| `install.sh:893-914` | **改**：core_plugins / ux_plugins 数组改为 `jq` 读 `plugin-manifest.json` |
| `README.md` / `README.zh-CN.md` | **改**：`## Installation` 顶部加 Option A / Option B 两种方式 |

---

## 11. 验证流程

实施完成后逐项验证：

1. **skills CLI 兼容性**：`npx -y skills add eleven-net-cn/llm-wiki-starter -g -y`，确认能解析 `skills/llm-wiki-starter/` 嵌套结构。失败 → 启动退化方案
2. **Skill 自然语言触发**：在 Claude Code 里说"帮我创建一个 llm-wiki 知识库"，看 Skill 是否被加载并展示工作流入口
3. **显式命令触发**：`/llm-wiki-starter --name test-kb --lang zh --dir /tmp/test-kb`，确认跳过 3 个交互输入直接执行
4. **多 AI CLI 兼容性**：至少 Claude Code + Codex 各跑一次完整流程
5. **OS 覆盖**：macOS 本地完整跑一次；Linux/Windows 用 docker / VM 或拾一在 Win 实机跑一次
6. **幂等性**：同目录重跑 Skill，确认所有 ✓ 跳过、零重装
7. **`plugin-manifest.json` 单源**：改一条插件，分别用 install.sh 和 Skill 各跑一次，确认两边都拿到改动
8. **json-canvas 软禁用生效**：装完后问 AI "给我画一个 canvas"，看选用 `obsidian-canvas-creator` 而非 `json-canvas`
9. **Web Clipper 检测**：手动装一次扩展，再跑 Skill，看检测命中；卸载后再跑，看是否打印官网链接
10. **失败收尾摘要**：故意断网装 Codex，看收尾摘要里"Manual install required"段是否正确列出

---

## 12. 关键决策记录

| 决策 | 选择 | 理由 |
|---|---|---|
| Skill 与 install.sh 关系 | 独立手册，Agent 原生执行 | 不受 OS / bash 限制 |
| 仓库布局 | `skills/llm-wiki-starter/` | 拾一指定；CLI 兼容性需验证 |
| AI 工具选项 | 5 选多选，默认 Claude Code | 保持"多 AI Agent 支持"承诺 |
| 模板获取 | curl tarball | 不依赖 git，Win 原生 cmd 友好 |
| Web Clipper | 检测 + 未装打链接 | 浏览器扩展无法脚本装 |
| Skill CLI 安装方式 | `npx -y skills add` | 不污染全局 npm，与现有 install.sh 一致 |
| AI CLI 登录/key 提示 | 不提示 | 装完即结束，配置属用户范畴 |
| Skill 检测路径 | `~/.agents` 优先于 `~/.claude` | install.sh 同步改 |
| json-canvas | 装上但软禁用 | CLI 不支持子集安装；硬删可能被 update 拉回 |
| 插件清单真源 | `plugin-manifest.json` 共用 | 避免两处维护 |
