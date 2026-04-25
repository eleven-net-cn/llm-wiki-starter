# <Wiki Name>

基于 [LLM Wiki 模式](https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f) 构建的个人知识库。

## 快速开始

1. 用 [Obsidian](https://obsidian.md) 打开本文件夹
2. 启动 AI 助手：`claude`
3. 开始你的第一次摄取

## 操作

### 1. 摄取（Ingest）— 添加知识

将源文档放入 `raw/` 或直接提供 URL：

```
摄取这篇文章：https://example.com/some-article
摄取所有新资料
```

LLM 会阅读源文档，创建摘要，提取概念，添加交叉引用，并更新目录。

### 2. 查询（Query）— 提问

```
X 和 Y 之间有什么关系？
对比 A 和 B
总结我们知道的关于 Z 主题的所有内容
```

LLM 会查阅 wiki 页面并综合回答，附带 `[[wikilink]]` 引用。

### 3. 巡检（Lint）— 健康检查

```
对 wiki 做一次健康检查
```

检查孤页、死链、过时内容、缺失概念和标签违规。

## 目录结构

- `raw/` — 源文档（人类管理，不可变）
- `wiki/` — LLM 编译的知识页面
- `CLAUDE.md` — [Claude Code](https://claude.ai/claude-code) Schema
- `AGENTS.md` — 兼容 [AGENTS.md 规范](https://github.com/anthropics/AGENTS-md-spec)的共享 Schema（Codex、Copilot、Gemini CLI、OpenCode 等）
