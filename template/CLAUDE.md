# LLM Wiki — Claude Code Schema

@AGENTS.md

> 基于 Andrej Karpathy 的 LLM Wiki 模式构建。本文件定义 LLM 如何维护这个知识库。
> 人类负责策划资料来源和提出问题；LLM 负责所有的总结、交叉引用、归档和维护工作。

## 架构

三层结构：

1. **`raw/`** — 不可变的源文档。LLM 只读不写。这是唯一的事实来源。
2. **`wiki/`** — LLM 生成和维护的 markdown 页面。摘要、实体页、概念页、对比、综合分析。
3. **本文件（`CLAUDE.md`）** — Schema 规范。定义结构、约定和工作流。

## 目录结构

```
<wiki-name>/
├── raw/                        # 原始资料（不可变）
│   ├── 剪藏/                   # 浏览器剪藏收件箱
│   ├── assets/                 # 图片、附件
│   └── <领域>/                 # 按知识领域分类
├── wiki/                       # LLM 维护的 wiki
│   ├── 概念/                   # 概念扫盲页
│   ├── 资料摘要/               # 摘要页
│   ├── 综合分析/               # 交叉分析
│   ├── 归档/                   # 过时页面
│   ├── assets/excalidraw/      # 图表
│   ├── Wiki 目录.md            # 内容目录
│   ├── 操作日志.md             # 操作日志
│   └── 知识库概览.md           # 概览页
├── canvas/                     # JSON Canvas
├── CLAUDE.md                   # 本 Schema 文件
├── AGENTS.md                   # OpenCode Schema
└── README.md                   # 仓库文档
```

## 三大操作

1. **Ingest（摄取）** — 将 raw 文件转为 wiki 页面
2. **Query（查询）** — 搜索、关联、回答问题
3. **Lint（巡检）** — 定期检查、归档、更新

## 页面格式

每个 wiki 页面使用 frontmatter：

```yaml
---
title: 页面标题
tags: [tag1, tag2]
created: 2026-04-24
updated: 2026-04-24
source: raw/<领域>/<文件名>.md
status: draft | active | archived
---
```

## 使用方式

启动 Claude Code 后，告诉 Agent：

- 摄取：`请摄取 raw/<领域>/文章名.md`
- 查询：`查找关于 xxx 的所有资料`
- 巡检：`检查 wiki 中过时的页面`