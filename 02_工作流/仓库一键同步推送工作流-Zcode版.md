---
title: 仓库一键同步推送工作流-Zcode版
created: 2026-08-01
updated: 2026-08-05
tags:
  - workflow/general
  - workflow/repository-sync
---
# 仓库一键同步推送工作流-Zcode版

## 目标

通过 `dual-git-ssh-sync` Skill/MCP，把已经复查并提交的差异安全增量推送到 GitHub 和 Gitee。只使用 SSH，不强推，不覆盖远端独有历史，不重复上传远端已有提交。

## 固定安全规则

1. GitHub、Gitee remote 必须使用 SSH。
2. 禁止 `git push --force`、`--force-with-lease`、`git reset`、删除分支和绕过校验。
3. 工作区有改动时，先生成文件级复查表，排除密钥、缓存、生成物和不应上传的大附件，再暂存明确批准的路径。
4. 推送前先 fetch 两端，任一远端存在本地没有的提交时立即停止，不自动合并或覆盖。
5. 只推送各远端缺少的提交和 Git 对象；已存在且未变化的文件不会重复上传。
6. GitHub LFS 版与 Gitee 普通文件/精简版可以保留不同提交历史，不为追求哈希一致而强推。
7. 新的外部上传必须得到用户确认；失败原因未变化时不得重复推送。

## Zcode 安装位置

- Skill：`/Users/wangzirui/.zcode/skills/dual-git-ssh-sync/SKILL.md`
- CLI：`/Users/wangzirui/.zcode/skills/dual-git-ssh-sync/scripts/dual_git_sync.py`
- MCP：`dual-git-ssh-sync`
- MCP 工具：`dual_git_status`、`dual_git_push`

## 推荐对话用法

### 只检查，不上传

> 使用 dual-git-ssh-sync，检查这个仓库的 GitHub/Gitee 差异，不要推送：`/仓库绝对路径`

Zcode 应调用 `dual_git_status`，参数中设置绝对仓库路径、`branch: main`、`fetch: true`。

### 确认后增量推送

> 确认使用 SSH，只推送已复查差异到 GitHub 和 Gitee。

Zcode 应调用 `dual_git_push`，参数中设置绝对仓库路径、`branch: main`、`confirm: true`。

## CLI 备用方式

MCP 不可用时使用同一套安全脚本：

```bash
python3 /Users/wangzirui/.zcode/skills/dual-git-ssh-sync/scripts/dual_git_sync.py \
  status \
  --repo "/仓库绝对路径" \
  --branch main \
  --fetch
```

用户确认后：

```bash
python3 /Users/wangzirui/.zcode/skills/dual-git-ssh-sync/scripts/dual_git_sync.py \
  push \
  --repo "/仓库绝对路径" \
  --branch main \
  --confirm
```

## 工作区有改动时

MCP 不负责盲目执行 `git add -A`。必须先完成以下步骤：

1. 查看 `git status --short`。
2. 生成差异文件复查表。
3. 检查 API Key、访问令牌、私钥、`.env`、缓存、临时目录和大文件。
4. 只暂存明确批准的路径并创建普通提交。
5. 再运行 `dual_git_status` 和 `dual_git_push`。

## 大文件与 LFS

- 普通 Git 单文件超过95 MiB时停止推送，先调整存储策略。
- Gitee 目标提交含 LFS 指针时默认停止，防止只有指针没有文件内容。
- 需要双版本时，以现有 Gitee 分支为基线创建普通文件/精简版提交；GitHub 继续使用完整 LFS 版。
- 禁止使用 `GIT_LFS_SKIP_PUSH` 冒充成功。

## 成功标准

- 工作区干净。
- 两个 remote 均为 SSH。
- 两端 `remote_only = 0`、`local_only = 0`，或属于已记录的远端专用存储差异。
- 返回实际推送的远端、分支和提交哈希；部分成功必须明确说明。

## 关联

- [[../01_长期记忆/用户长期偏好]]
- [[GitHub仓库推送工作流]]
- [[Gitee仓库同步与推送工作流]]
