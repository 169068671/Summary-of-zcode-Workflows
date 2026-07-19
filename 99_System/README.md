---
title: 记忆库核验工具
created: 2026-07-17
updated: 2026-07-17
tags:
  - system/validation
---

# 记忆库核验工具

`validate_vault.py` 用于每次记忆库写入后检查：

- Markdown 笔记是否具有标题和标签属性。
- 已使用的标签是否登记到标签索引。
- 长期记忆、工作流、决策和项目是否进入内容索引。
- Obsidian 双链目标是否存在。
- `.obsidian` 中的 JSON 配置是否可解析。
- 是否出现疑似明文 API 密钥。

只有输出 `PASS` 时才能宣称记忆库更新完成。

运行方式：

```bash
python3 /Users/wangzirui/Zcode工作流汇总/99_System/validate_vault.py
```
