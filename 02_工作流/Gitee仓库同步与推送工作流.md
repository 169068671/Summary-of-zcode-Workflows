---
title: Gitee仓库同步与推送工作流
created: 2026-07-17
updated: 2026-08-05
tags:
  - workflow/general
  - workflow/repository-sync
---
# Gitee仓库同步与推送工作流

## 当前口径

Gitee 推送统一纳入 [[仓库一键同步推送工作流-Zcode版]]，使用 `dual-git-ssh-sync` Skill/MCP。旧版临时分支强推和覆盖远端历史的方案已经停用。

## 安全规则

1. 只使用 SSH remote。
2. 先调用 `dual_git_status` 并设置 `fetch: true`。
3. Gitee 存在远端独有提交或历史分叉时停止，不覆盖、不重置、不强推。
4. 工作区必须先完成文件级复查和正常提交。
5. Gitee 目标提交含 LFS 指针时默认停止；为该远端维护普通文件/精简版提交。
6. 用户确认后才调用 `dual_git_push`，并设置 `confirm: true`。

## 推荐调用

> 使用 dual-git-ssh-sync 检查这个仓库，只读取 GitHub/Gitee 差异，不推送：`/仓库绝对路径`

确认结果后：

> 确认用 SSH 增量推送已复查提交到 GitHub 和 Gitee，禁止强推。

## Gitee 精简版

当 GitHub 使用 LFS、Gitee 不支持相同存储策略时：

1. 保留 GitHub 完整版主线。
2. 从现有 Gitee 分支创建临时工作树。
3. 排除大附件和所有 LFS 指针，以普通 Git 对象构建精简快照。
4. 提交必须以当前 Gitee 分支为父提交，保证可以快进。
5. 推送完成后删除临时工作树，记录两端提交哈希和排除项。

不得使用 `GIT_LFS_SKIP_PUSH`，也不得为了让两端哈希相同而覆盖任一远端历史。

## 旧脚本兼容入口

`02_工作流/gitee_sync.sh` 只保留只读审计能力，不再执行提交或推送。实际上传必须走 Skill/MCP 或其同源 CLI。

## 成功标准

- Gitee remote 使用 SSH。
- 普通同步时 `remote_only = 0`、`local_only = 0`。
- 远端专用精简版有明确提交、排除清单和复查记录。
- 无密钥、缓存、LFS 断链或超限大文件进入提交。
