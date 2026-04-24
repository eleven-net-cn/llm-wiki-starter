# <Wiki 名称>

<!-- 在初始化时由 install.sh 填充 -->

基于 LLM Wiki 模式构建的个人知识库。

## 结构

- `raw/` — 原始资料（人类管理）
- `wiki/` — LLM 生成的知识页面
- `CLAUDE.md` — Schema 规范

## 使用

启动 Claude Code：
```bash
cd <wiki目录>
claude
```

摄取资料：
```
请摄取 raw/<领域>/文章名.md
```