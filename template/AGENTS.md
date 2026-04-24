# LLM Wiki — OpenCode Schema

> 与 CLAUDE.md 保持一致，定义 OpenCode/其他 Agent 如何维护这个知识库。

## 约定

1. **只读 raw/** — LLM 不修改原始资料
2. **全权 wiki/** — LLM 拥有 wiki 层的所有编辑权
3. **遵守 Schema** — 结构和命名遵循 CLAUDE.md 定义

## 操作

- **Ingest** — 从 raw 提取知识，写入 wiki
- **Query** — 搜索 wiki，回答问题，提供引用
- **Lint** — 定期巡检，归档过时内容

详见 CLAUDE.md。