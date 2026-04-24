[English](./README.en.md) | 简体中文

# llm-wiki-starter

一行命令创建 LLM Wiki 知识库 —— 基于 [Andrej Karpathy 的 LLM Wiki 模式](https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f)。

```bash
curl -fsSL https://raw.githubusercontent.com/eleven-net-cn/llm-wiki-starter/main/install.sh | bash
```

## 什么是 LLM Wiki？

传统 RAG 每次查询都从零开始检索知识。LLM Wiki 不同 —— LLM **增量式地构建和维护一个持久化的 wiki**，交叉引用自动建立，矛盾被标记，综合分析持续更新。每次添加新资料都会让 wiki 更丰富。

**三层架构**：`raw/`（不可变源文档）→ `wiki/`（LLM 维护）→ Schema（`AGENTS.md`）

**三大操作**：Ingest（摄取）→ Query（查询）→ Lint（巡检）

## 安装

### 一键安装

```bash
curl -fsSL https://raw.githubusercontent.com/eleven-net-cn/llm-wiki-starter/main/install.sh | bash
```

安装程序会：
1. 创建 wiki 目录结构
2. 检测系统已安装的工具
3. 展示安装计划并询问确认
4. 安装缺少的工具（Obsidian、插件、Node.js、Claude Code、Skills、Git）
5. 初始化 Git 仓库（如果 Git 可用）

如果拒绝自动安装，脚本会打印手动安装指南及官方链接。

### 手动克隆

```bash
git clone https://github.com/eleven-net-cn/llm-wiki-starter my-wiki
cd my-wiki
bash install.sh
```

脚本会检测到当前在模板仓库内，自动跳过下载步骤。

### 参数

| 参数 | 说明 | 默认值 |
|------|------|--------|
| `--name <name>` | Wiki 名称 | `my-wiki` |
| `--dir <directory>` | 目标目录 | `./<name>` |
| `--lang <zh\|en>` | Wiki 语言 | `zh` |
| `--non-interactive` | 跳过所有提示，使用默认值 | - |
| `--skip-install` | 只创建结构，跳过工具安装 | - |

环境变量 `LLM_WIKI_DIR` 也可以指定目标目录。

```bash
# 非交互式安装
bash install.sh --non-interactive --name my-ai-wiki

# 英文 wiki
bash install.sh --lang en --name my-wiki

# 仅创建结构（CI / 快速测试）
bash install.sh --name test-wiki --dir /tmp/test --skip-install
```

## 快速开始

```bash
# 1. 安装
curl -fsSL https://raw.githubusercontent.com/eleven-net-cn/llm-wiki-starter/main/install.sh | bash

# 2. 用 Obsidian 打开
cd my-wiki && open -a Obsidian .

# 3. 启动 AI Agent
claude

# 4. 摄取第一份资料
> 摄取这篇文章：https://example.com/some-article

# 5. 查询知识库
> X 和 Y 之间有什么关系？

# 6. 运行健康检查
> 运行一次 wiki 巡检
```

## 生成的目录结构

```
my-wiki/
├── raw/                     # 不可变的源文档
│   ├── 收件箱/               # Web Clipper 收件箱
│   ├── <领域>/               # 按知识领域组织
│   └── assets/              # 图片、附件
├── wiki/                    # LLM 维护的知识库
│   ├── <领域>/               # 领域编译页
│   ├── 概念/                 # 概念定义页
│   ├── 资料摘要/             # 资料摘要页
│   ├── 综合分析/             # 交叉分析
│   ├── 归档/                 # 已归档页面
│   ├── assets/excalidraw/   # 图表
│   ├── Wiki 目录.md          # 内容目录
│   ├── 操作日志.md           # 操作时间线
│   └── 知识库概览.md         # 导航入口
├── canvas/                  # JSON Canvas 可视化地图
├── CLAUDE.md                # Claude Code 规范（导入 AGENTS.md）
├── AGENTS.md                # 共享 wiki 规范（唯一真相源）
└── README.md
```

领域目录由 LLM 在首次摄取时自动创建。

## 安装内容

### 工具

| 工具 | 用途 | 安装方式 |
|------|------|----------|
| **Obsidian** | Wiki 编辑器和查看器 | `brew install --cask obsidian` / snap |
| **Node.js** | Claude Code 和 Skills CLI 依赖 | brew / apt / dnf |
| **Claude Code** | AI Agent（推荐） | `npm install -g @anthropic-ai/claude-code` |
| **Git** | 版本控制（可选） | xcode-select / brew / apt |

### Obsidian 插件

| 插件 | 用途 | 优先级 |
|------|------|--------|
| **Dataview** | 基于 frontmatter 的 SQL 风格查询 | 必要 |
| **Templater** | 模板系统 | 必要 |
| **Obsidian Git** | 自动 git 提交/推送 | 必要（需 Git） |
| **Linter** | Markdown 格式化 | 必要 |
| **Custom Sort** | 通过 sortspec 控制文件浏览器排序 | 必要 |
| **Tag Wrangler** | 标签管理 | 推荐 |
| **Strange New Worlds** | 显示 wikilink 引用计数 | 推荐 |
| **Homepage** | 设置首页 | 推荐 |

### Claude Code Skills

通过 [Skills CLI](https://github.com/vercel-labs/skills) 全局安装（`npx skills add -g -y`），自动链接到所有已检测的 Agent。

| Skills | 用途 |
|--------|------|
| **[kepano/obsidian-skills](https://github.com/kepano/obsidian-skills)** | Obsidian markdown、CLI 交互、网页清洗（defuddle） |
| **[axtonliu/visual-skills](https://github.com/axtonliu/axton-obsidian-visual-skills)** | Excalidraw 图表、Mermaid 可视化、Canvas 地图 |

### 浏览器扩展（推荐）

| 扩展 | 用途 |
|------|------|
| **[Obsidian Web Clipper](https://chromewebstore.google.com/detail/obsidian-web-clipper/cnjifjpddelmedmihgijeibhnjfabmlf)** | 将网页文章直接剪藏到 `raw/收件箱/` 供 LLM 摄取 |

## 支持的 AI Agent

生成的 Schema 兼容以下 Agent：

| Agent | Schema 文件 | 链接 |
|-------|-------------|------|
| **Claude Code** | `CLAUDE.md` → 导入 `AGENTS.md` | [claude.ai/claude-code](https://claude.ai/claude-code) |
| **OpenCode** 等更多 | `AGENTS.md` | [github.com/anomalyco/opencode](https://github.com/anomalyco/opencode) |

## 对比

| | llm-wiki-starter | [llm-wikid](https://github.com/shannhk/llm-wikid) | 手动搭建 |
|---|---|---|---|
| 搭建时间 | **5 分钟** | 20 分钟 | 2–4 小时 |
| 语言 | 中文 / 英文 | 英文 | 自定义 |
| 领域 | 通用（不限领域） | 内容/营销 | 自写 Schema |
| 架构 | 三层（raw/wiki/schema） | 两层（KBL+BF） | 自定义 |
| Agent 支持 | Claude Code + OpenCode + Gemini CLI | Claude Code | 自行配置 |
| 套件安装 | 全自动（Obsidian + 插件 + Skills） | 手动 | 手动 |

## License

[MIT](LICENSE)
