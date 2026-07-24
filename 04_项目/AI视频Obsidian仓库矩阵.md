---
title: AI 视频 Obsidian 仓库矩阵
created: 2026-07-21
updated: 2026-07-21
tags:
  - project
  - workflow/ai-video
---

# AI 视频 Obsidian 仓库矩阵

## 已启用仓库

| Obsidian 知识库 | 本地路径 | GitHub 仓库 | 同步插件 ID | 默认分支 | 可见性 |
|---|---|---|---|---|---|
| 丁美霞AI视频 | `/Users/wangzirui/丁美霞AI视频` | [Ding-Meixia-AI-Video](https://github.com/169068671/Ding-Meixia-AI-Video) | `ding-meixia-github-sync` | `main` | 公开 |
| 王华军AI视频 | `/Users/wangzirui/王华军AI视频` | [Wang-Huajun-AI-Video](https://github.com/169068671/Wang-Huajun-AI-Video) | `wang-huajun-github-sync` | `main` | 公开 |
| 王子睿AI视频 | `/Users/wangzirui/王子睿AI视频` | [Wang-Zirui-AI-Video](https://github.com/169068671/Wang-Zirui-AI-Video) | `wang-zirui-github-sync` | `main` | 公开 |
| 王子墨AI视频 | `/Users/wangzirui/王子墨AI视频` | [Wang-Zimo-AI-Video](https://github.com/169068671/Wang-Zimo-AI-Video) | `wang-zimo-github-sync` | `main` | 公开 |
| 眼镜店AI视频 | `/Users/wangzirui/眼镜店AI视频` | [AI-Video-for-Optical-Shops](https://github.com/169068671/AI-Video-for-Optical-Shops) | `optical-shop-github-sync` | `main` | 公开 |
| 咖啡馆AI视频 | `/Users/wangzirui/咖啡馆AI视频` | [AI-Video-of-a-Coffee-Shop](https://github.com/169068671/AI-Video-of-a-Coffee-Shop) | `coffee-shop-github-sync` | `main` | 公开 |

## 统一标准

- 每个知识库使用独立 GitHub 仓库、独立 Obsidian 同步插件和 `main` 分支。
- 普通图片、视频和音频按 `.gitattributes` 自动进入 Git LFS；`attachments/上传锚点/` 中的小体积上传锚点使用普通 Git。
- 原始高分辨率人物、场景和品牌锚点只在本地保留；GitHub 同步只使用最长边 1600 像素、单张不超过 2 MB 的一一对应上传锚点，并在上传前核验 SHA-256 清单。
- 上传前执行 `99_System/validate_vault.py`，核验 YAML、标签、索引、双链、JSON 和疑似明文密钥。
- 同步脚本不保存 Token、不强推、不自动替换已有远程；远端历史存在时先拉取并 rebase。
- 新项目遵循 [[../02_工作流/AI视频制作工作流]]，新增核心笔记同步更新内容索引与标签索引。

## 备注说明

本笔记于 2026-07-21 从 Codex 工作流汇总对齐抄录并改造为 Zcode 版本。表中 6 个 AI 视频知识库及其 GitHub 仓库、同步插件 ID 均为已建成的独立项目事实，与 Codex / Zcode 的工作流汇总本体无关；本笔记只用于在 Zcode 工作流汇总中提供矩阵索引。
