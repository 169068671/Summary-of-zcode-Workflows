---
title: 课题与论文知识库 GitHub 同步
created: 2026-07-21
updated: 2026-07-21
tags:
  - project
  - workflow/general
---

# 课题与论文知识库 GitHub 同步

## 固定配置

- Obsidian 知识库：`/Users/wangzirui/课题与论文知识库`
- GitHub 仓库：<https://github.com/169068671/Research-topics-and-papers-knowledgebase>
- 默认分支：`main`
- Obsidian 插件 ID：`research-papers-github-sync`
- 插件目录：`.obsidian/plugins/research-papers-github-sync`
- 安全同步脚本：`plugins/github-vault-sync/scripts/sync_vault.py`

## 同步规则

- 点击 Obsidian 左侧云上传按钮，或执行命令"一键同步整个仓库到 GitHub"。
- 上传前核验 JSON、超限文件、疑似凭据文件和明文访问令牌。
- 插件不保存 Token，认证交给电脑现有的 Git 凭据管理器。
- 不强推、不替换远程；远端存在更新时先获取并安全变基。
- PDF、Office、压缩包和音视频文件使用 Git LFS；`.DS_Store`、Obsidian 本机工作区状态和 `node_modules` 不上传。

## 调用入口

- GitHub 同步工作流：[[../02_工作流/GitHub仓库一键同步工作流]]

## 备注

本笔记于 2026-07-21 从 Codex 工作流汇总对齐抄录并改造为 Zcode 版本。课题与论文知识库本体（`/Users/wangzirui/课题与论文知识库`）及其 GitHub 仓库、Obsidian 同步插件均为独立建成的项目事实，与 Zcode 工作流汇总本体无关；本笔记只用于在 Zcode 工作流汇总中登记该项目。
