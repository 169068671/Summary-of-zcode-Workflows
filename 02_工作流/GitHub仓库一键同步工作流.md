---
title: GitHub仓库一键同步工作流
created: 2026-07-21
updated: 2026-08-04
type: workflow
record_type: workflow
status: 启用
version: 1.1.0
source: 借鉴同名一键同步工作流的安全边界与测试连接说明，保留zcode的HTTPS+gh认证
tags:
  - workflow/general
  - workflow/repository-sync
---

# GitHub仓库一键同步工作流

## 目标

把整个"Zcode工作流汇总" Obsidian 知识库安全同步到 [Summary-of-zcode-Workflows](https://github.com/169068671/Summary-of-zcode-Workflows)，同时提供 Obsidian 按钮和 Zcode 对话两个入口。

## 固定配置

- 本地知识库：`/Users/wangzirui/Zcode工作流汇总`
- GitHub 仓库：`https://github.com/169068671/Summary-of-zcode-Workflows.git`
- 远程名：`origin`
- 分支：`main`
- 安全同步脚本：`plugins/github-vault-sync/scripts/sync_vault.py`

## 两个使用入口

### Obsidian

1. 重载 Obsidian。
2. 点击左侧边栏的云上传图标。
3. 或打开命令面板，执行"Zcode GitHub Sync: 一键同步整个仓库到 GitHub"。

### Zcode 对话

在 Zcode 对话中说：

> 把 Zcode 工作流汇总安全同步到 GitHub。

Zcode 会执行 `python3 plugins/github-vault-sync/scripts/sync_vault.py`，调用同一个同步脚本。

## 同步顺序

1. 运行[[../99_System/README|知识库强制核验]]。
2. 检查待上传文件中是否出现 `.env`、私钥或凭据文件。
3. 如尚未初始化 Git，创建 `main` 分支。
4. 检查 `origin` 是否指向固定 GitHub 仓库；同仓库旧 HTTPS 地址可迁移为 SSH，不同仓库则停止。
5. 提交所有新增、修改和删除。
6. 远程 `main` 已存在时，先 fetch 并 rebase。
7. 无冲突后推送到 `origin/main`。
8. 回报分支、提交哈希和推送结果。

## 安全边界

- 不强推，不改写历史，不自动替换已有远程。
- 只允许把同一个固定仓库的旧 HTTPS 地址迁移为 SSH，不替换其他仓库。
- 已有上游若为 `gitee/main` 等其他远程，推送 GitHub 时保留该跟踪关系。
- 本地与远程历史不相关时停止。
- rebase 冲突时自动取消 rebase 并停止。
- 知识库核验不通过时不提交、不推送。
- 不在 Obsidian 插件、设置或知识库中保存 GitHub Token。

## 测试连接（不上传）

首次使用或排查故障时，先验证读写权限和当前分支是否允许安全快进，但不上传内容：

```bash
git fetch origin
git push --dry-run origin main
```

`--dry-run` 会执行远端读取和权限检查，输出推送预览但不真正传输对象。通过后再执行正式同步。

## 首次认证

如果提示 GitHub 认证失败，在终端执行：

```bash
gh auth login -h github.com
gh auth setup-git
```

认证完成后再点击同步。不要把 Token 复制到笔记、Obsidian 插件设置或对话中。

## 完成标准

- [ ] 同步脚本返回 `ok: true` 和 `pushed: true`。
- [ ] GitHub 远程 `main` 指向本次返回的提交哈希。
- [ ] 本地工作区无未提交变更。
- [ ] 核验日志中无断链、无新标签缺失、无明文密钥。

## 关联

- [[../00_HOME/Zcode启动必读]]
- [[通用任务工作流]]
- [[../01_长期记忆/工具与环境注意事项]]
