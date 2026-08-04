---
title: GitHub仓库推送工作流
created: 2026-07-28
updated: 2026-08-05
type: workflow
record_type: workflow
status: 启用
version: 2.0.0
source: 统一接入 dual-git-ssh-sync Skill/MCP
tags:
  - workflow/general
  - git
  - github
  - workflow/repository-sync
---
# GitHub仓库推送工作流

## 当前入口

GitHub 推送统一使用 [[仓库一键同步推送工作流-Zcode版]] 和 `dual-git-ssh-sync` Skill/MCP。不再使用自动 `git add -A`、固定次数盲目重试、HTTPS 凭据或覆盖历史的旧脚本。

## 固定规则

1. GitHub remote 必须使用 SSH，remote 名称由工具自动识别，不假设一定叫 `origin`。
2. 状态检查只授权 fetch 和差异审计，不授权提交或上传。
3. 用户明确确认上传后才调用 `dual_git_push`。
4. 工作区不干净、远端存在独有提交、疑似密钥或超限普通 Git 文件时停止。
5. GitHub LFS 对象保持 LFS，不静默转换为普通文件。
6. 网络或认证失败后记录原因；原因未改变时不重复提交推送任务。

## 推荐调用

只读检查：

> 使用 dual-git-ssh-sync 检查这个仓库的 GitHub/Gitee 差异，不推送：`/仓库绝对路径`

确认上传：

> 确认使用 SSH，只推送已复查的差异提交到 GitHub 和 Gitee。

## MCP 工具

- `dual_git_status`：发现 GitHub/Gitee SSH remote，fetch 后返回工作区和 ahead/behind 状态。
- `dual_git_push`：再次执行安全校验，只推送远端缺少的提交；必须传入 `confirm: true`。

## GitHub 专用 LFS

- 推送前确认 LFS 对象本地可用。
- 单个普通 Git blob 超过95 MiB时停止并改用 LFS或排除。
- Gitee 不兼容相同 LFS 策略时，为 Gitee 维护可快进的普通文件/精简版分支，不修改 GitHub 完整版历史。

## 成功标准

- GitHub remote 为 SSH。
- 工作区干净且提交已复查。
- 推送后 `remote_only = 0`、`local_only = 0`。
- 报告实际分支、提交哈希、LFS结果；部分成功不冒充全部完成。

## 关联

- [[仓库一键同步推送工作流-Zcode版]]
- [[Gitee仓库同步与推送工作流]]
- [[../01_长期记忆/用户长期偏好]]
