[English](./README.md) | 简体中文

# llm-wiki-starter

一条命令自动搭建 [Andrej Karpathy 的 LLM Wiki](https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f) AI 知识库。

自动安装 Claude Code + Obsidian + 推荐的插件（Skills & Plugins & 主题 & 快捷键）等，让 AI 帮你持续积累和维护个人知识体系。

自动兼容 Claude Code、Codex、Copilot、Gemini CLI、OpenCode 等主流 AI Agent 使用。

![ai-wiki.zh-CN](./assets/ai-wiki.zh-CN.png)

## 安装

任选一种方式：

### 方式 A — Skill 安装（推荐，面向 AI Agent 用户）

一条命令装好本 Skill，任何 AI CLI（Claude Code / Codex / Copilot CLI / Gemini CLI / OpenCode）都能帮你搭建知识库：

```bash
npx -y skills add eleven-net-cn/llm-wiki-starter -g -y
```

然后在你的 AI CLI 里说 **"创建 llm-wiki 知识库"**（English: "create llm wiki"），或直接运行 `/llm-wiki-starter`。

Agent 会自动检测已装工具，并引导你完成搭建 —— 不受操作系统和包管理器的限制。

**Skill 命令参数**（全部可选；`/llm-wiki-starter` 不带参数即进入交互式。命名与 `install.sh` 对齐）：

| 参数 | 默认值 | 行为 |
|------|--------|------|
| `--bash` | 关闭 | **熟手快捷模式**：跳过 AI 6 阶段流程，直接 `curl \| bash` 调 install.sh，并转发其它参数。极大节省 token，结果一致。 |
| `--name <wiki-name>` | （交互式提示） | Wiki 目录名 |
| `--lang <en\|zh>` | `en` | 模板语言版本 |
| `--dir <path>` | `$(pwd)` | 父目录；vault 创建在 `<dir>/<name>` |
| `--only-tools` | 关闭 | 仅安装工具 / Skills / Obsidian，不创建 wiki |
| `--only-wiki` | 关闭 | 跳过工具安装；创建 wiki + 配置插件（假设工具已就绪） |
| `--only-obsidian` | 关闭 | 跳过工具与 wiki 创建；仅在 `--dir` 指向的已有 vault 中安装插件 + 主题 |

三个 `--only-*` 参数互斥。

示例：

```
/llm-wiki-starter                                                    # 交互式，走完整 SOP
/llm-wiki-starter --bash --name research-wiki --lang zh              # 快速、非交互、不走 AI 引导
/llm-wiki-starter --name research-wiki --lang zh                     # 交互式，AI 引导
/llm-wiki-starter --only-tools                                       # 仅安装工具
/llm-wiki-starter --only-wiki --name fresh-wiki --lang en            # 工具已就绪，仅创建 wiki
/llm-wiki-starter --only-obsidian --dir ~/Documents/CODE/my-wiki     # 仅给已有 vault 安装插件
```

#### Skill 使用技巧

- **触发可靠性**：`/llm-wiki-starter` 总能触发。自然语言（"创建 llm-wiki 知识库"、"create llm wiki"）也能触发，但**最好包含 "llm-wiki" 或 "本地"** 这种区分词，避免被本机其他同类 skill（lark-wiki、wiki-ingest 等）抢词。如果自然语言没有触发，改用显式 slash 命令。
- **裸命令探索参数**：`/llm-wiki-starter` 不带参数会先打印一行所有可用参数提示，再进入交互式 —— 这就是 inline help。
- **每次创建都是新知识库**：用同名重跑会被要求改名；工具 / skills / Obsidian / 插件的检测是幂等的，已装的会自动跳过。
- **按你想做什么选模式**：
  - 全新机器第一次 → 裸 `/llm-wiki-starter`（或 `--bash` 走非交互式）
  - 工具齐全，只想加新 wiki → `--only-wiki --name <新名字>`
  - 给已有 vault 重装插件（如 Obsidian 重置后）→ `--only-obsidian --dir <已有 vault>`
- **`--bash` 模式前置**：需要 `curl`、`bash` shell、能访问 GitHub。Windows 用户必须在 Git Bash 或 WSL2 里跑（cmd.exe / PowerShell 无法 pipe 到 bash）。
- **更新 Skill**：再跑一次 `npx -y skills add eleven-net-cn/llm-wiki-starter -g -y` 会重新 clone 并覆盖本地 `~/.agents/skills/llm-wiki-starter/`（以及 `~/.claude/skills/` 的软链）。
- **国内用户走代理**：`npx skills add` 内部用 `git clone`，`--bash` 模式用 `curl`。**两套都要配**：`git config --global http.proxy http://127.0.0.1:<端口>` **加上** shell `export https_proxy=http://127.0.0.1:<端口>`。只配其中一个，另一个工具仍连不上 GitHub。
- **跨 AI CLI**：同一份 Skill 文件被软链到 `~/.agents/skills/` 和 `~/.claude/skills/`，所以 Claude Code、Codex、Gemini CLI、Cursor、Copilot CLI、OpenCode 都能识别，无需多次安装。
- **Canvas 约束已嵌入新 vault**：生成的 `AGENTS.md` 已告知未来的 AI 会话用 `obsidian-canvas-creator`（来自 `axtonliu/visual-skills`）创建 `.canvas` 文件 —— 你不需要每次重复说明。

### 方式 B — 一键 bash 脚本

```bash
curl -fsSL https://raw.githubusercontent.com/eleven-net-cn/llm-wiki-starter/main/install.sh | bash
```
![create-ai-wiki](./assets/create-ai-wiki.svg)

> **Windows 用户**：安装脚本是 bash 脚本，请在 **Git Bash**（推荐）或 **WSL2** 中执行 —— `cmd.exe` 与 PowerShell 无法运行 bash。先安装 [Git for Windows](https://git-scm.com/download/win)（自带 Git Bash + curl），再执行 `git config --global core.autocrlf input` 避免 `bad interpreter` 错误。脚本会自动检测 winget / Chocolatey / Scoop 来安装 Obsidian、Node.js、Git。

参数示例：

```bash
# 仅检测、安装全局工具套件（Claude Code、Obsidian、NodeJS、Agent Skills 等）
curl -fsSL https://raw.githubusercontent.com/eleven-net-cn/llm-wiki-starter/main/install.sh | bash -s -- --only-tools

# 跳过全局工具套件的检测、安装，仅创建 wiki 知识库
curl -fsSL https://raw.githubusercontent.com/eleven-net-cn/llm-wiki-starter/main/install.sh | bash -s -- --only-wiki

# 跳过全局工具套件的检测、安装和 wiki 知识库创建，仅在当前所在仓库初始化配置推荐的 Obsidian 插件、主题、快捷键等配置
curl -fsSL https://raw.githubusercontent.com/eleven-net-cn/llm-wiki-starter/main/install.sh | bash -s -- --only-obsidian
```

### 参数

支持的参数，按需选用：

| 参数 | 说明 | 默认值 |
|------|------|--------|
| `--name <name>` | Wiki 名称 | `my-wiki` |
| `--dir <directory>` | 目标目录 | `./<name>` |
| `--lang <en\|zh>` | Wiki 语言 | `en` |
| `--yes, -y` | 跳过所有提示，使用默认值 | - |
| `--only-tools` | 仅安装工具套件，不创建 wiki 知识库 | - |
| `--only-wiki` | 仅创建 wiki 和 Obsidian 配置，不安装工具 | - |
| `--only-obsidian` | 仅在已有 vault 中配置 Obsidian | - |

### 检测安装

自动检测系统已有工具，只安装缺少的部分：

**工具 & Skills**

- ✅ **Claude Code** — 默认推荐的 AI Agent
- ✅ **Node.js** — Claude Code 和 Skills CLI 运行时
- ✅ **Obsidian** — Wiki 编辑器和可视化图谱查看器
- ✅ **[kepano/obsidian-skills](https://github.com/kepano/obsidian-skills)** — Obsidian Markdown、CLI 交互、Bases 数据库视图、网页清洗（defuddle）
- ✅ **[axtonliu/visual-skills](https://github.com/axtonliu/axton-obsidian-visual-skills)** — Excalidraw 图表、Mermaid 可视化、Obsidian Canvas、JSON Canvas
- ✅ **Git** — 版本控制（可选）

> Skills 通过 [Skills CLI](https://github.com/vercel-labs/skills) 全局安装，跨 Agent 共享。

**Obsidian**

- **插件**（17 个插件：9 Core + 8 UX，随 wiki 自动配置）

    Core 插件（llm-wiki 核心功能必需）：

    - ✅ **[Claudian](https://github.com/YishenTu/claudian)** — Vault 内嵌 Claude Code / Codex / OpenCode agent，侧边栏对话直接读写文件
    - ✅ **Dataview** — 基于 frontmatter 的 SQL 风格查询
    - ✅ **Templater** — 页面模板系统
    - ✅ **Linter** — 自动 Markdown 格式化
    - ✅ **Custom Sort** — 通过 sortspec 控制文件浏览器排序
    - ✅ **Obsidian Git** — 自动 git 提交/推送（需 Git）
    - ✅ **Tag Wrangler** — 重命名、合并和管理标签
    - ✅ **Strange New Worlds** — 显示 wikilink 引用计数
    - ✅ **Homepage** — 打开 vault 时设置首页

    UX 插件（增强 Obsidian 编辑体验）：

    - ✅ **Omnisearch** — 全库模糊搜索
    - ✅ **Switcher++** — 快速切换器，支持标题导航
    - ✅ **Minimal Theme Settings** — Minimal 主题配置
    - ✅ **Hider** — 隐藏 UI 元素，界面更简洁
    - ✅ **Editing Toolbar** — Word 风格编辑工具栏 + F11 全屏快捷键
    - ✅ **Excalidraw** — 手绘风格图表
    - ✅ **Quiet Outline** — 增强大纲视图
    - ✅ **Open in Terminal** — 打开 vault 到终端

- **主题**

    ✅ **Minimal** — 简洁、无干扰主题（自动下载）

- **快捷键**

    - `Cmd+Shift+F` → Omnisearch（模糊搜索）
    - `Cmd+R` → 快速切换器（标题导航）
    - `Cmd+F11` → 工作区全屏
    - `Cmd+Shift+F11` → 编辑器全屏专注

**浏览器扩展（推荐使用，不会自动安装）**

- **[Obsidian Web Clipper](https://chromewebstore.google.com/detail/obsidian-web-clipper/cnjifjpddelmedmihgijeibhnjfabmlf)** — 将网页文章直接剪藏到 `raw/收件箱/` 供 LLM 摄取

## 开始使用

```bash
# 用 Obsidian 打开
cd my-wiki && open -a Obsidian .

# 启动 AI Agent（也可使用 codex / copilot / gemini 等）
claude
```

然后与 AI 对话：

- **摄取** → `摄取这篇文章：https://example.com/some-article`
- **查询** → `X 和 Y 之间有什么关系？`
- **巡检** → `运行一次 wiki 巡检`

## 知识库结构

```
my-wiki/
├── raw/                     # 不可变的源文档（LLM 只读）
│   ├── 收件箱/               # Web Clipper 收件箱（摄取时自动分类）
│   ├── <领域>/               # 按知识领域组织
│   └── assets/              # 图片、附件
├── wiki/                    # LLM 维护的知识库
│   ├── <领域>/               # 领域编译页
│   ├── 概念/                 # 概念定义页
│   ├── 资料摘要/             # 资料摘要页
│   ├── 综合分析/             # 交叉分析
│   ├── 归档/                 # 已归档页面
│   └── assets/excalidraw/   # 图表
├── canvas/                  # JSON Canvas 可视化地图
├── templates/               # 页面模板（每种 type 一个，LLM 创建页面时引用）
├── AGENTS.md                # Wiki 规范（唯一真相源）
└── CLAUDE.md                # Claude Code 配置（导入 AGENTS.md）
```

> **提示**：领域目录（如 `AI Agent/`、`机器学习/`）会在首次摄取时自动创建。告诉 AI 你的知识属于什么领域，或者让它根据内容自行判断。

## 什么是 LLM Wiki？

[LLM Wiki](https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f) 是 Andrej Karpathy 提出的知识管理模式：不同于传统 RAG 每次查询从零检索，LLM **增量式地构建和维护一个持久化的 wiki** —— 交叉引用自动建立，矛盾被标记，综合分析持续更新。每次添加新资料都会让 wiki 更丰富。

**适用场景**：个人知识管理、技术调研、领域学习笔记、团队知识库 —— 任何需要 AI 帮你长期积累和整理知识的场景。

**工作方式**：[Claude Code](https://claude.ai/claude-code) 作为 AI Agent 负责读写和维护 wiki；[Obsidian](https://obsidian.md) 作为可视化编辑器和阅读器。你通过与 AI 对话来摄取资料、查询知识、运行巡检 —— 同时在 Obsidian 中浏览和导航知识图谱。

**三层架构**：`raw/`（不可变源文档）→ `wiki/`（LLM 维护的页面）→ Schema（`AGENTS.md`）

**三大操作**：**Ingest**（摄取）→ **Query**（查询）→ **Lint**（巡检）

## 致谢

- [Andrej Karpathy — LLM Wiki](https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f)

## License

[MIT](LICENSE)
