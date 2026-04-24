# llm-wiki-starter

一行命令创建 LLM Wiki 知识库 — 基于 [Andrej Karpathy 的 LLM Wiki 模式](https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f)。

```bash
curl -fsSL https://raw.githubusercontent.com/axtonliu/llm-wiki-starter/main/install.sh | bash
```

## 什么是 LLM Wiki？

传统 RAG 每次查询从零开始发现知识。LLM Wiki 不同 — LLM **增量构建和维护一个持久化的 wiki**，交叉引用已建立，矛盾已标记，综合分析持续更新。每添加一份资料，wiki 都在变得更丰富。

**三层架构**：`raw/`（不可变源资料）→ `wiki/`（LLM 维护）→ Schema（`CLAUDE.md`）

**三大操作**：Ingest（摄取）→ Query（查询）→ Lint（巡检）

## 安装

### 交互式安装

```bash
curl -fsSL https://raw.githubusercontent.com/axtonliu/llm-wiki-starter/main/install.sh | bash
```

脚本会引导你完成 5 步配置：Wiki 名称 → 知识领域 → Agent Schema → Skills → 生成。

### 指定参数安装

```bash
# AI 领域知识库
curl -fsSL https://raw.githubusercontent.com/axtonliu/llm-wiki-starter/main/install.sh | bash -s -- --preset ai --name my-ai-wiki

# 软件开发知识库
curl -fsSL https://raw.githubusercontent.com/axtonliu/llm-wiki-starter/main/install.sh | bash -s -- --preset dev --name dev-wiki

# 学术研究知识库
curl -fsSL https://raw.githubusercontent.com/axtonliu/llm-wiki-starter/main/install.sh | bash -s -- --preset research --name paper-wiki

# 完全静默（CI 场景）
bash install.sh --non-interactive --preset ai --name my-wiki --dir ./my-wiki
```

### 参数

| 参数 | 说明 | 默认值 |
|------|------|--------|
| `--name <名称>` | Wiki 名称 | `my-wiki` |
| `--preset <预设>` | 领域预设：`ai` / `dev` / `research` / `blank` | 交互选择 |
| `--dir <目录>` | 目标目录 | `./<名称>` |
| `--non-interactive` | 跳过所有交互，使用默认值 | - |

环境变量 `LLM_WIKI_DIR` 也可指定目标目录。

## 领域预设

| 预设 | 领域 |
|------|------|
| **AI（人工智能）** | LLM 基础、AI Agent、AI Coding、提示工程、AI 基础设施、AI 生态、AI 前沿研究 |
| **软件开发** | 前端、后端、架构、DevOps、数据库、安全、团队协作 |
| **学术研究** | 文献综述、方法论、实验记录、数据分析、论文写作 |
| **空白** | 完全自定义，交互式输入领域名称 |

每个预设包含对应的目录结构、受控标签词汇表和分类规则。

## 生成内容

```
my-wiki/
├── raw/                     # 不可变源资料
│   ├── 剪藏/                # Web Clipper 收件箱
│   ├── <领域 1>/
│   ├── <领域 2>/
│   └── assets/
├── wiki/                    # LLM 维护的知识库
│   ├── <领域 1>/
│   ├── <领域 2>/
│   ├── 概念/                # 概念扫盲页
│   ├── 资料摘要/            # 摘要页
│   ├── 综合分析/            # 交叉分析
│   ├── 归档/
│   ├── Wiki 目录.md         # 内容索引
│   ├── 操作日志.md          # 时间线日志
│   └── 知识库概览.md        # 门面页
├── canvas/                  # JSON Canvas
├── CLAUDE.md                # Claude Code Schema
├── AGENTS.md                # OpenCode Schema
├── README.md
└── .gitignore
```

## 快速开始

```bash
# 1. 安装
curl -fsSL https://raw.githubusercontent.com/axtonliu/llm-wiki-starter/main/install.sh | bash -s -- --preset ai --name my-ai-wiki

# 2. 用 Obsidian 打开
open -a Obsidian ./my-ai-wiki

# 3. 启动 AI Agent
cd my-ai-wiki && claude

# 4. 摄取第一份资料
> 帮我 ingest 这篇文章：https://example.com/some-article

# 5. 查询
> MCP 协议是什么？

# 6. 巡检
> 请对 wiki 运行一次健康检查
```

## 推荐工具

### AI Agent（任选其一）

- [Claude Code](https://claude.ai/claude-code) — 读取 CLAUDE.md
- [OpenCode](https://github.com/anomalyco/opencode) — 读取 AGENTS.md
- [Gemini CLI](https://github.com/google/gemini-cli) — 读取 AGENTS.md

### Obsidian 插件

| 插件 | 用途 | 优先级 |
|------|------|--------|
| **Dataview** | 对 frontmatter 运行类 SQL 查询 | 必装 |
| **Templater** | 模板系统 | 必装 |
| **Obsidian Git** | 自动 git commit/push | 必装 |
| **Linter** | 格式化 markdown | 必装 |
| **Tag Wrangler** | 标签管理 | 推荐 |
| **Strange New Worlds** | 显示 wikilink 引用数 | 推荐 |
| **Excalidraw** | 手绘风图表 | 可选 |

### Obsidian Skills（安装时可选）

安装时选择"安装 kepano/obsidian-skills"即可自动配置：
- `obsidian-markdown` — Obsidian 风味 markdown
- `obsidian-cli` — CLI 交互
- `defuddle` — 网页内容清洗
- `obsidian-bases` — 动态视图
- `json-canvas` — Canvas 文件

## 与同类项目的对比

| 维度 | llm-wiki-starter | [llm-wikid](https://github.com/shannhk/llm-wikid) | 从零手搭 |
|------|------------------|---------|----------|
| 起步耗时 | **5 分钟** | 20 分钟 | 2-4 小时 |
| 语言 | 中文优先 | 英文 | 自定 |
| 领域 | 交互式选择（4 预设） | 内容创作/营销 | 手写 Schema |
| 架构 | 三层（raw/wiki/schema） | 双层（KBL+BF） | 自定 |
| Agent 支持 | Claude Code + OpenCode | Claude Code | 自配 |
| Skills | 可选自动安装 | 预置 slash 命令 | 手装 |

## 致谢

- 模式：[Andrej Karpathy — LLM Wiki](https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f)
- 蓝本：[ai-wiki](https://github.com/axtonliu/ai-wiki) — 经过实战验证的 AI 领域 LLM Wiki（235 页）
- 参考：[llm-wikid](https://github.com/shannhk/llm-wikid) — KBL+BF 双层脚手架

## License

[MIT](LICENSE)
