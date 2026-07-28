---
title: Gitee仓库同步与推送工作流
created: 2026-07-28
updated: 2026-07-28
status: 启用
tags:
  - workflow/general
  - gitee
  - git
  - backup
---

# Gitee仓库同步与推送工作流

## 目标

将本地多个 Git 仓库（GitHub 远程）批量同步/推送到 Gitee，作为 GitHub 的国内镜像备份。覆盖三类需求：

- GitHub 访问不稳定，需要国内镜像备份。
- 给本地仓库添加 Gitee 双远程并批量推送。
- Git LFS 文件需转换为普通文件后推送（Gitee 免费版不支持 LFS）。

> Gitee 企业免费版有 **10 个仓库额度**，单仓库约 1G 软限制。

## 前置条件清单

| 步骤 | 命令/操作 | 验证 |
|------|----------|------|
| 1. 配置 SSH 密钥 | `ssh-keygen -t ed25519 -C "邮箱"` | `cat ~/.ssh/id_ed25519.pub` |
| 2. 公钥添加到 Gitee | 网页 → 设置 → SSH 公钥 | `ssh -T git@gitee.com` |
| 3. 创建 Gitee 企业/组织 | 网页或 MCP | 组织名 `dongtaishiruimoyanjingdian` |
| 4. 本地仓库加 Gitee remote | `git remote add gitee git@gitee.com:组织名/仓库名.git` | `git remote -v` |
| 5. 本地 Gitee MCP 已挂载 | 见 [[Gitee_MCP配置文档]] | Zcode 会话可调 `mcp__gitee__*` |

> **SSH 验证成功**会显示：`Hi xxx! You've successfully authenticated...`

## 本地 Gitee MCP 与 git 的职责边界

本工作流**统一用本地 `mcp__gitee__*` 工具**（Zcode 通过 stdio 挂载 `~/.local/bin/mcp-gitee`）处理 Gitee **元数据**；**代码传输只能用 git**，因为 MCP 没有 push/clone/remote 类工具。

### 完整工具对照表（25 个）

| 工具 | 类别 | 本工作流是否用到 | 说明 |
|------|------|----------------|------|
| `list_user_repos` | 仓库 | ✅ 建仓前检查 | 列出已有仓库，避免重复创建 |
| `create_repo` | 仓库 | ✅ 批量建仓 | 创建个人/组织/企业仓库 |
| `get_file_content` | 仓库 | ✅ 验证推送 | 推送后读取远端文件确认 |
| `search_files_by_content` | 仓库 | ⬜ | 按内容搜索仓库文件 |
| `search_open_source_repositories` | 仓库 | ⬜ | 搜索开源仓库 |
| `fork_repository` | 仓库 | ⬜ | Fork 仓库 |
| `create_release` | 仓库 | ⬜ | 创建发行版 |
| `list_releases` | 仓库 | ⬜ | 列出发行版 |
| `compare_branches_tags` | 仓库 | ⬜ | 对比分支/Tag |
| `create_issue` | Issue | ⬜ | 可用于记录推送异常 |
| `update_issue` | Issue | ⬜ | 更新 Issue |
| `get_repo_issue_detail` | Issue | ⬜ | 查 Issue 详情 |
| `list_repo_issues` | Issue | ⬜ | 列出 Issue |
| `list_comments` | Issue/PR | ⬜ | 列出评论 |
| `create_comment` | Issue/PR | ⬜ | 评论 Issue/PR |
| `list_repo_pulls` | PR | ⬜ | 列出 PR |
| `create_pull` | PR | ⬜ | 创建 PR |
| `update_pull` | PR | ⬜ | 更新 PR |
| `get_pull_detail` | PR | ⬜ | 查 PR 详情 |
| `get_diff_files` | PR | ⬜ | 查 PR 差异文件 |
| `merge_pull` | PR | ⬜ | 合并 PR |
| `manage_pull_review` | PR | ⬜ | 审查 PR |
| `get_user_info` | 用户 | ✅ 验证 token | 确认认证身份 |
| `search_users` | 用户 | ⬜ | 搜索用户 |
| `list_user_notifications` | 通知 | ⬜ | 列出通知 |

> **关键**：上表无任何 `git push` / `git clone` / `git remote` 类工具。代码推送、LFS 转换、remote 管理只能用本地 `git` 命令。

## 用本地 MCP 建仓与检查

以下操作在 Zcode 会话中直接调用 `mcp__gitee__*` 工具，无需手动跑命令行。配置细节见 [[Gitee_MCP配置文档]]。

### 1. 验证认证身份

调用 `mcp__gitee__get_user_info`，确认返回用户 `wanghjdz`，token 有效。

### 2. 列出已有仓库（避免重复建仓）

调用 `mcp__gitee__list_user_repos`，参数：

```
affiliation: enterprise_member
page: 1
per_page: 100
```

> 注意：不要同时传 `type` 和 `affiliation`，会报 422。返回的 `content[0].text` 直接是 JSON 数组。

### 3. 批量创建仓库

对本地每个待推送仓库，调用 `mcp__gitee__create_repo`，参数：

```
owner_type: enterprise
enterprise: dongtaishiruimoyanjingdian
name: <与本地文件夹同名>
path: <同 name>
private: true
auto_init: false
```

> 仓库名与本地文件夹同名，便于 `git remote add gitee git@gitee.com:dongtaishiruimoyanjingdian/<name>.git` 对应。

### 4. 推送后验证远端文件

调用 `mcp__gitee__get_file_content`，参数：

```
owner: dongtaishiruimoyanjingdian
repo: <仓库名>
path: README.md
```

确认远端已有内容，推送成功。

## 批量检查本地仓库状态

```bash
cd /Users/wangzirui
for dir in */; do
  [ -d "$dir/.git" ] || continue
  name=$(basename "$dir")
  has_gitee=$(git -C "$dir" remote -v 2>/dev/null | grep gitee | head -1)
  lfs_count=$(git -C "$dir" lfs ls-files 2>/dev/null | wc -l | tr -d ' ')
  size=$(du -sh "$dir" 2>/dev/null | cut -f1)
  echo "$name | ${has_gitee:+有Gitee remote}${has_gitee:-无remote} | LFS: $lfs_count | 大小: $size"
done
```

## 推送流程

### 无 LFS 文件：直接推送

```bash
cd /Users/wangzirui/仓库名
git add -A
git commit -m "sync: 同步最新内容" 2>/dev/null || true
git push gitee main
```

### 有 LFS 文件：转换后推送

Gitee 免费版不支持 LFS，需把 LFS 指针文件临时转为真实内容再推送。保存为 `push_to_gitee.sh`：

```bash
#!/bin/bash
# push_to_gitee.sh - 推送单个仓库到 Gitee（含 LFS 转换）
# 用法: ./push_to_gitee.sh /Users/wangzirui/仓库名

REPO_PATH="${1:-$(pwd)}"
cd "$REPO_PATH" || { echo "无法进入目录: $REPO_PATH"; exit 1; }

# 检查 Gitee remote
if ! git remote -v | grep -q gitee; then
  echo "错误: 没有 Gitee remote"
  exit 1
fi

CURRENT=$(git branch --show-current)

# 保存当前状态
git stash push -m "gitee-push-backup" 2>/dev/null || true

# 创建临时分支
git checkout -b gitee-temp

# 步骤 1: 临时添加 LFS 规则，检出真实文件
cat >> .gitattributes << 'LFS_RULES'
*.png filter=lfs diff=lfs merge=lfs -text
*.jpg filter=lfs diff=lfs merge=lfs -text
*.jpeg filter=lfs diff=lfs merge=lfs -text
*.gif filter=lfs diff=lfs merge=lfs -text
*.mp4 filter=lfs diff=lfs merge=lfs -text
*.mov filter=lfs diff=lfs merge=lfs -text
*.pdf filter=lfs diff=lfs merge=lfs -text
*.docx filter=lfs diff=lfs merge=lfs -text
*.pptx filter=lfs diff=lfs merge=lfs -text
*.m4a filter=lfs diff=lfs merge=lfs -text
*.mp3 filter=lfs diff=lfs merge=lfs -text
*.wav filter=lfs diff=lfs merge=lfs -text
LFS_RULES

git add .gitattributes
git commit -m "temp: add LFS rules for checkout"

# 检出真实文件内容
git lfs checkout

# 步骤 2: 移除 LFS filter，防止转回指针
git config --local --remove-section filter.lfs 2>/dev/null || true
git config --global --remove-section filter.lfs 2>/dev/null || true

# 步骤 3: 恢复原始 .gitattributes
git show "$CURRENT:.gitattributes" > .gitattributes 2>/dev/null || rm -f .gitattributes

# 步骤 4: 强制重新添加文件（真实内容进入索引）
git add --renormalize .
git add -A

# 步骤 5: 提交并推送
git commit -m "gitee: convert LFS to regular files"
git push gitee gitee-temp:main --force

# 步骤 6: 清理，恢复原状
git checkout "$CURRENT"
git branch -D gitee-temp
git lfs install
git lfs checkout

# 恢复 stash
git stash pop 2>/dev/null || true

echo "✅ 推送完成: $REPO_PATH
```

### 脚本副作用与本地恢复（实测发现）

> 以下结论来自 2026-07-28 在 `教科研数据仓库`（2 个 LFS PDF）上的实测。

脚本用 `--force` 把转换后的普通文件版本推到 Gitee main，**Gitee 远端 main 的 HEAD 从此是普通文件版本，不再是 LFS 指针版本**。这是设计意图（Gitee 不支持 LFS），但有三个副作用需要知道：

1. **本地 LFS 跟踪会断**：脚本第 2 步全局移除了 `filter.lfs`，第 6 步 `git lfs install` + `git lfs checkout` 虽能重建，但若本地 main 已被脚本或后续操作 reset 到转换后的提交，`git lfs ls-files` 会返回空（因为该提交里已是普通文件，LFS 不再跟踪）。
2. **本地 main 落后于 gitee/main**：脚本只 force push 到远端，不动本地 main。推送后本地 main 停在原 LFS 版本，gitee/main 指向新的转换版本，本地显示「落后 N 个提交」。
3. **本地与 Gitee 历史分叉**：本地是 LFS 指针历史，Gitee 是普通文件历史，两者不再 fast-forward 关系。后续再次推送该仓库时，**必须继续用本脚本**（或 `git push gitee main --force`），不能普通 push。

**推送后恢复本地 LFS 状态**（让本地回到正常的 LFS 跟踪，继续用 GitHub origin 工作）：

```bash
cd /Users/wangzirui/仓库名
# 本地 main 保持原 LFS 版本，不要 reset 到 gitee/main
git lfs install
git lfs checkout          # 重新检出 LFS 真实文件
git lfs ls-files          # 确认 LFS 跟踪已恢复（应列出文件）
```

> 本地 main 与 gitee/main 的分叉是**预期状态**：本地走 GitHub LFS，Gitee 走普通文件镜像，互不影响。只要不把本地 main reset 到 gitee/main，LFS 跟踪就不会断。

### 批量推送（按大小排序，小仓库先推）

```bash
cd /Users/wangzirui
for dir in */; do
  [ -d "$dir/.git" ] || continue
  name=$(basename "$dir")
  size=$(du -sh "$dir" 2>/dev/null | cut -f1)
  echo "$size $name"
done | sort -h | while read -r size name; do
  repo_path="/Users/wangzirui/$name"
  [ -d "$repo_path/.git" ] || continue

  echo ""
  echo "=== 推送: $name ($size) ==="

  has_gitee=$(git -C "$repo_path" remote -v 2>/dev/null | grep gitee)
  if [ -z "$has_gitee" ]; then
    echo "跳过: 无 Gitee remote"
    continue
  fi

  lfs_count=$(cd "$repo_path" && git lfs ls-files 2>/dev/null | wc -l | tr -d ' ')
  if [ "$lfs_count" -gt 0 ]; then
    echo "检测到 $lfs_count 个 LFS 文件，使用转换模式..."
    ./push_to_gitee.sh "$repo_path"
  else
    echo "无 LFS 文件，直接推送..."
    cd "$repo_path" && git push gitee main 2>&1
  fi
done
```

## SSH 超时配置

大仓库推送时 SSH 可能超时，`~/.ssh/config` 添加：

```
Host gitee.com
    HostName gitee.com
    User git
    IdentityFile ~/.ssh/id_ed25519
    ServerAliveInterval 60
    ServerAliveCountMax 10
    TCPKeepAlive yes
```

## Gitee 配额注意事项

| 套餐 | 单仓库大小 | 单文件大小 |
|------|-----------|-----------|
| 免费版 | 500M~1G | 50M |
| 高级版 | 2G | 200M |
| 尊享版 | 3G | 300M |

- 超过 1GB 推送时会警告 `exceeds quota 1024MB`，但通常还有 **50 次推送机会**。
- 超过 2G/3G 需升级套餐，或只推小文件（Markdown、配置），大文件留 GitHub LFS。

## 实际推送记录（已验证）

| 仓库 | 大小 | LFS 文件 | 状态 |
|------|------|---------|------|
| Zcode工作流汇总 | ~50M | 无 | ✅ 成功 |
| 课题与论文知识库 | ~100M | 有 | ✅ 成功 |
| 孩子们的知识点 | ~200M | 有 | ✅ 成功 |
| 王子墨AI视频 | ~300M | 有 | ✅ 成功 |
| 王子睿AI视频 | ~300M | 有 | ✅ 成功 |
| 咖啡馆AI视频 | ~200M | 有 | ✅ 成功 |
| 眼镜店AI视频 | ~200M | 有 | ✅ 成功 |
| 王华军AI视频 | ~300M | 有 | ✅ 成功 |
| 拍我AI PAI.VIDEO | ~200M | 有 | ✅ 成功 |
| 教科研数据仓库 | ~38M | 有（2 PDF） | ✅ 成功（2026-07-28 实测，见副作用小节） |
| 丁美霞AI视频 | ~2.3G | 有 | ❌ 超时（需拆分） |

## 常见问题速查

| 问题 | 解决 |
|------|------|
| `Permission denied` | 检查 SSH 公钥是否添加到 Gitee |
| `LFS only supported in paid` | 使用上述 LFS 转换脚本 |
| `Operation timed out` | 配置 `ServerAliveInterval 60`，或分多次小提交 |
| `exceeds quota 1024MB` | 仓库超 1G，可继续推（有次数限制）或拆分 |
| `git lfs checkout` 后仍是 131 字节 | `.gitattributes` 缺 LFS 规则，用脚本临时添加 |
| `git add -A` 检测不到变更 | 先 `git config --remove-section filter.lfs`，再 `git add --renormalize .` |
| 推送后 `git lfs ls-files` 为空 | 本地 main 被重置到 gitee/main（转换版），LFS 不再跟踪。reset 回原 LFS 版本后 `git lfs install && git lfs checkout` 恢复，见「脚本副作用与本地恢复」 |
| Gitee 上有旧内容要覆盖 | `git push gitee <分支>:main --force` |
| MCP 报 422 `cannot specify type` | 不要同时传 `type` 和 `affiliation`，只用 `affiliation` |

## 关联

- [[Gitee_MCP配置文档]]
- [[GitHub仓库一键同步工作流]]
- [[../01_长期记忆/工具与环境注意事项]]
- [[../00_HOME/Zcode启动必读]]
