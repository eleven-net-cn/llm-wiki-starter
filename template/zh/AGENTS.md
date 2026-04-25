# <Wiki Name> — LLM Wiki Schema

> 基于 [Andrej Karpathy 的 LLM Wiki 模式](https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f) 构建。
> 本文件定义 LLM 如何维护这个知识库。
> 人类负责策划资料来源和提出问题；LLM 负责所有的总结、交叉引用、归档和维护工作。
>
> 本文件是共享的 wiki 规范（Single Source of Truth）。Claude Code 通过 `@AGENTS.md` 导入，
> Codex、Copilot、OpenCode、Gemini CLI 等直接读取。**绝不将本文件内容复制到 CLAUDE.md。**

## 架构

三层结构：

1. **`raw/`** — 不可变的源文档。LLM 只读不写。
2. **`wiki/`** — LLM 生成和维护的 markdown 页面。LLM 完全拥有这一层。
3. **本文件（`AGENTS.md`）** — Schema 规范。定义结构、约定和工作流。

## 目录结构

```
<wiki-name>/
├── raw/                        # 第一层：原始资料（不可变）
│   ├── 收件箱/                  # Web Clipper 收件箱（统一入口）
│   ├── assets/                 # 图片、附件
│   └── <领域>/                  # 按知识领域组织
├── wiki/                       # 第二层：LLM 维护的 wiki
│   ├── <领域>/                  # 领域编译页
│   ├── 概念/                   # 概念页（跨领域知识轴）
│   ├── 资料摘要/               # 每份已摄取资料的摘要页
│   ├── 综合分析/               # 交叉分析与洞察
│   ├── 归档/                   # 已归档的过时页面
│   ├── assets/excalidraw/      # Excalidraw 图表
│   ├── Wiki 目录.md            # 内容目录（LLM 维护）
│   ├── 操作日志.md             # 时间线操作日志
│   └── 知识库概览.md           # 知识库落地页
├── canvas/                     # JSON Canvas 可视化地图
├── templates/                  # 页面模板（每种 type 一个，LLM 创建页面时引用）
├── CLAUDE.md                   # Claude Code Schema（导入本文件）
├── AGENTS.md                   # 本 Schema 文件
└── README.md                   # 仓库文档
```

`raw/` 和 `wiki/` 下的领域目录在首次 ingest 时自动创建，无需预配置。

## 页面格式

### Frontmatter 规范

每个 wiki 页面必须包含以下 frontmatter：

```yaml
---
title: 页面标题
type: entity | concept | topic | comparison | source | synthesis
tags: [tag1, tag2, tag3]
aliases: [别名1, 别名2]           # 可选，Obsidian 别名
created: YYYY-MM-DD
updated: YYYY-MM-DD
sources:
  - "[[资料摘要：xxx]]"            # 使用 wikilink 格式，确保可点击
confidence: high | medium | low
related_concepts: []               # 可选，concept 类型页面使用
source_url: https://...            # 可选，仅 source 类型页面
media: article | paper | video     # 可选，仅 source 类型页面
---
```

### 正文结构

创建 wiki 页面时，**必须先读取 `templates/<type>.md`** 获取对应类型的模板，严格按模板定义的章节结构组织正文。禁止自行编造章节结构。

| type | 模板文件 | 用途 |
|------|---------|------|
| entity | `templates/entity.md` | 产品、项目、组织、人物 |
| concept | `templates/concept.md` | 概念定义与扫盲 |
| topic | `templates/topic.md` | 领域主题、综合指南 |
| comparison | `templates/comparison.md` | 对比分析 |
| source | `templates/source.md` | 资料摘要 |
| synthesis | `templates/synthesis.md` | 交叉分析与洞察 |

### 页面命名

- **文件名 = frontmatter `title`**：文件名必须与标题完全一致
- 半角 `:` → 全角 `：`（macOS 文件名限制）
- 资料摘要页：`资料摘要：` 前缀 + 简称，如 `资料摘要：MCP 协议.md`
- 概念页：描述性名称，如 `Transformer.md`、`RAG（检索增强生成）.md`

### 概念页原则

- 每页 100–250 行，聚焦权威定义和扫盲
- 有 `raw/` 资料支撑的标 `confidence: high`，纯基于训练知识的标 `confidence: medium`
- 已有领域详解页的概念，概念页做精简定义 + 链接到领域详解页，不重复内容
- 所有概念页必须包含 `概念` 标签

## 标签体系

使用**受控词汇表**。标签简洁（每个标签 ≤6 字）。

**内容类型标签：**
`概念`, `教程`, `深度`, `综述`, `观点`, `资讯`, `工具`, `范式`, `反模式`, `案例`, `基准`, `最佳实践`

**元标签（生命周期属性）：**
`长青`（稳定、持久）, `易过时`（变化快、定期回顾）, `基础`（前置知识）, `进阶`（需深入背景）

**领域标签：** 根据知识库领域自定义，保持一致性。

<!-- 不同领域的标签示例：
  AI:       大模型, 智能体, AI编程, 提示工程, 基础设施, 生态, 研究
  软件:     前端, 后端, 架构, 运维, 数据库, 安全, 团队
  研究:     文献, 方法论, 实验, 数据分析, 写作
-->

**标签原则：**
- 新标签前先检查是否已有等价标签
- 一词一义：同义词统一到一个标签
- 厂商/产品/协议名保持原有形式（如 `openai`、`claude-code`）

## 操作流程

### 1. Ingest（摄取）

当用户将新资料添加到 `raw/` 并要求摄取时：

1. **完整阅读**源文档。
2. **与用户讨论**关键要点，确认需要强调的内容。
3. **创建**资料摘要页到 `wiki/资料摘要/`，包含 frontmatter。

#### URL 直接摄取

用户可以直接提供 URL，由 LLM 代为完成采集和摄取：

```
摄取这篇文章：https://example.com/some-article
```

流程：
1. 使用 `defuddle` 提取干净的 markdown：`npx defuddle parse <url> --markdown`
2. 保存到 `raw/<领域>/` 作为不可变源文档
3. 继续标准 ingest 流程（步骤 1–10）

#### 收件箱摄取

`raw/收件箱/` 是浏览器 Web Clipper 的**统一收件箱**。当用户说"摄取新资料"时，LLM **必须首先扫描** `raw/收件箱/`：

1. **扫描** `raw/收件箱/` 中所有文件
2. **阅读**内容，判断所属领域
3. **移动**到对应 `raw/<领域>/` 目录
4. **继续**标准 ingest 流程

文件处理后从 `raw/收件箱/` 移出（不保留副本）。每次 ingest 都应检查此目录。

#### 标准流程（续）
4. **确定领域** — 将页面放入匹配的目录。若跨多个领域，选择最匹配的，其余用 tags 关联。
5. **更新或创建**实体页、概念页和主题页到对应领域目录。
6. **图表生成** — 若资料满足以下任一条件，生成至少一张图表并嵌入对应 wiki 页面：
   - 描述系统/框架**架构**（分层、模块、组件拓扑）
   - 包含**执行循环**或流程（流水线、循环流程）
   - 包含**多角色协作**（多服务交互、消息传递）
   - 包含**数据流**（输入→处理→输出）
   - 包含**层次结构**或分类（能力栈、分类树）

   方案选择：架构/流程/数据流 → **Excalidraw**（存 `wiki/assets/excalidraw/`）；关系地图 → **JSON Canvas**（存 `canvas/`）；简单序列/状态 → **Mermaid**（内联）。

   嵌入：`![[图表名.excalidraw]]` 或 Mermaid 代码块。**禁止**用 ASCII 字符画代替。

   跳过条件：纯观点文章 / 数据榜单；单一线性步骤（≤3 步）；已有同主题图表可复用。
7. **概念提取** — 识别资料中的核心概念：
   - 检查 `wiki/概念/` 是否已有对应页面
   - 若无，新建概念页（使用概念页格式）
   - 若有，更新已有页面的来源和相关内容
8. **标记矛盾** — 若新资料与已有页面冲突，标注双方立场并附引用。
9. **添加交叉引用** — 在新旧页面间双向添加 `[[wikilinks]]`。
10. **更新目录和日志**：
    - 更新 `wiki/Wiki 目录.md`
    - 追加到 `wiki/操作日志.md`：
    ```
    ## [YYYY-MM-DD] ingest | 资料标题
    - 来源：raw/<领域>/<文件名>.md
    - 新建页面：列表
    - 更新页面：列表
    - 新增概念：列表（如有）
    - 新增图表：列表（如有）
    - 核心洞察：一句话
    ```

### 2. Query（查询）

当用户提问时：

1. **阅读** `wiki/Wiki 目录.md` 查找相关页面。
2. **阅读**相关 wiki 页面（不是原始资料 — wiki 是编译后的知识）。
3. **综合回答**并附 `[[page]]` 引用。
4. **若回答有实质价值**，建议保存为新 wiki 页面（对比、综合等）。
5. **若 wiki 缺少相关信息**，明确说明 — 然后检查原始资料或建议需要摄取的来源。
6. **追加**到 `wiki/操作日志.md`：
    ```
    ## [YYYY-MM-DD] query | 简要问题
    - 查阅页面：列表
    - 结果：已回答 | 已保存为 wiki/综合分析/page.md | 发现知识空白
    ```

### 3. Lint（巡检）

当用户要求健康检查时（或定期执行）：

1. **孤页** — 没有入站链接的页面。
2. **死链** — `[[wikilinks]]` 指向不存在的页面。
3. **过时页面** — 超过 30 天未更新且标记为 `易过时` 的页面。
4. **缺失页面** — 在多个页面中被提及但缺少独立页面的概念。
5. **矛盾** — 页面间的冲突声明（标记供人类审核）。
6. **标签规范** — 不在词汇表中的标签、重复标签、未打标签的页面。
7. **资料覆盖** — 尚未摄取的 raw 资料。
8. **概念覆盖** — 领域页多次提及但 `wiki/概念/` 中缺少独立页面的概念。
9. **追加**检查结果到 `wiki/操作日志.md`。

## Obsidian 集成

本目录即为 Obsidian vault。遵循以下规则：

- 使用 `[[wikilinks]]` 语法做交叉引用（内部页面不使用 markdown 链接）。
- 使用 `![[image.png]]` 嵌入 `raw/assets/` 中的图片。
- 尊重 Obsidian 的 `.obsidian/` 配置目录 — 不要直接修改。

### 可视化图表

Wiki 页面中的图表**不使用 ASCII 字符画**，按以下优先级选择：

| 优先级 | 方案 | 适用场景 | 存放位置 |
|:---:|------|----------|----------|
| 1 | **Excalidraw** | 流程图、架构图、数据流、复杂逻辑 | `wiki/assets/excalidraw/` |
| 2 | **JSON Canvas** | 知识关系地图、空间布局 | `canvas/` |
| 3 | **Mermaid** | 序列图、状态图、文档内简单图表 | wiki 页面内联 |

简单线性流程和对比表格保留文本。

**Excalidraw 规范：**
- 存放 `wiki/assets/excalidraw/`，命名 `<主题> <图类型>.excalidraw.md`
- 嵌入：`![[图表名.excalidraw]]`
- 统一配色：蓝 `#a5d8ff`（主流程）、绿 `#b2f2bb`（输出）、橙 `#ffd8a8`（条件）、紫 `#d0bfff`（扩展）
- 字体：`fontFamily = 5`、`roughness = 0`
- 填充：`fillStyle = 'solid'`（纯色，禁止 hachure 斜线填充）

### 使用 Defuddle 清洗网页内容

摄取网页文章时，先用 `defuddle` 提取干净的 markdown：
```bash
npx defuddle parse https://example.com/article --markdown
```
去除导航、广告和杂乱内容 — 节省 token 并产出更干净的资料。

## 置信度

- **high** — 来源可靠，多个相互印证的引用，信息稳定。
- **medium** — 单一来源，或可能有尚未捕捉到的细微差别。
- **low** — 初步的，基于有限数据，或可能很快变化。

## 约束

- 绝不修改 `raw/` 中的文件。
- 绝不编造信息。不确定时将 confidence 标记为 `low`。
- 始终使用上述 frontmatter 格式创建 wiki 页面。
- 每次操作后始终更新 `wiki/Wiki 目录.md` 和 `wiki/操作日志.md`。
- 页面不超过约 500 行。超出则拆分。
- 内容匹配时优先更新已有页面，而非新建。
- frontmatter 中的 `sources` 字段必须使用 `[[wikilink]]` 格式。
- **保留来源链接**：提到 GitHub 仓库、官方文档等权威来源时，以 `[显示名](url)` 形式就地融入正文 — 不单开参考链接节。
- **ingest / lint / query 操作只修改 wiki 页面，绝不修改 `CLAUDE.md` 或 `AGENTS.md`。** Schema 文件只在用户明确要求修改规范时才编辑。

### 知识分组（自动归组）

当同一知识主题的文档数量 **> 1** 时，必须将其归入专属子文件夹。`raw/` 和 `wiki/` 下均适用此规则。

**触发条件：** 某个知识主题在同一领域目录下出现第 2 份文档时，自动创建子文件夹并将所有相关文档移入。

**命名规则：** 文件夹名 = 知识主题名，尽量精简。`raw/` 和 `wiki/` 下使用相同的子文件夹名。

**例外：** 跨主题的概览/对比页面留在领域根目录。

### 归档

`wiki/归档/` 用于存放已过时或不再维护的 wiki 页面。Lint 巡检中发现过时页面（超过 30 天未更新且标记为 `易过时`）时，应建议将其移入 `wiki/归档/`。归档页面保留原始内容，但在 frontmatter 中添加 `archived: YYYY-MM-DD` 字段，并从 `wiki/Wiki 目录.md` 中移除。
