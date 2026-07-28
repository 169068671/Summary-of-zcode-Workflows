---
title: Gitee仓库批量推送工作流
created: 2026-07-28
updated: 2026-07-28
status: 启用
tags:
  - workflow/general
  - gitee
  - git
  - backup
---

# Gitee仓库批量推送工作流

## 场景

把本地多个 Git 仓库（GitHub 远程）批量推送到 Gitee 作为镜像备份。Gitee 企业免费版有 **10 个仓库额度**，适合作为 GitHub 的国内备用方案。

## 前置条件清单

| 步骤 | 命令 | 验证 |
|------|------|------|
| 1. 安装 gitee-cli | `brew install gitee-cli` | `gitee --version` |
| 2. 配置 SSH 密钥 | `ssh-keygen -t ed25519 -C "你的邮箱"` | `cat ~/.ssh/id_ed25519.pub` |
| 3. 公钥添加到 Gitee | 网页 → 设置 → SSH 公钥 | `ssh -T git@gitee.com` |
| 4. 创建 Gitee 企业/组织 | 网页操作 | 记住组织名 |
| 5. 确保本地仓库有 Gitee remote | `git remote add gitee git@gitee.com:组织名/仓库名.git` | `git remote -v` |

> **SSH 验证成功会显示**：`Hi xxx! You've successfully authenticated...`

## 快速开始（3 步推送）

### 第 1 步：检查所有仓库状态

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

### 第 2 步：创建 Gitee 仓库（如未创建）

```bash
# 在 Gitee 网页上创建，或使用 API
# 组织名：dongtaishiruimoyanjingdian
# 仓库名与本地文件夹同名
```

### 第 3 步：批量推送

```bash
cd /Users/wangzirui

# 按大小排序，小仓库先推
for dir in */; do
  [ -d "$dir/.git" ] || continue
  name=$(basename "$dir")
  size=$(du -sh "$dir" 2>/dev/null | cut -f1)
  echo "$size $name"
done | sort -h | while read -r size name; do
  repo_path="/Users/wangzirui/$name"
  [ -d "$repo_path/.git" ] || continue

  echo ""
  echo "========================================"
  echo "推送: $name ($size)"
  echo "========================================"

  # 检查是否有 Gitee remote
  has_gitee=$(git -C "$repo_path" remote -v 2>/dev/null | grep gitee)
  if [ -z "$has_gitee" ]; then
    echo "跳过: 无 Gitee remote"
    continue
  fi

  # 检查是否有 LFS 文件
  lfs_count=$(cd "$repo_path" && git lfs ls-files 2>/dev/null | wc -l | tr -d ' ')

  if [ "$lfs_count" -gt 0 ]; then
    echo "检测到 $lfs_count 个 LFS 文件，使用转换模式..."
    push_lfs_repo "$repo_path"
  else
    echo "无 LFS 文件，直接推送..."
    cd "$repo_path" && git push gitee main 2>&1
  fi
done
```

## 有 LFS 文件的仓库推送

### 一键脚本

保存为 `push_to_gitee.sh`，给执行权限 `chmod +x push_to_gitee.sh`：

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

echo "✅ 推送完成: $REPO_PATH"
```

### 使用方式

```bash
# 单个仓库
./push_to_gitee.sh /Users/wangzirui/孩子们的知识点

# 批量推送所有含 LFS 的仓库
cd /Users/wangzirui
for dir in */; do
  [ -d "$dir/.git" ] || continue
  lfs_count=$(git -C "$dir" lfs ls-files 2>/dev/null | wc -l | tr -d ' ')
  [ "$lfs_count" -gt 0 ] && ./push_to_gitee.sh "/Users/wangzirui/$dir"
done
```

## SSH 配置（防止大仓库超时）

`~/.ssh/config`：

```
Host gitee.com
    HostName gitee.com
    User git
    IdentityFile ~/.ssh/id_ed25519
    ServerAliveInterval 60
    ServerAliveCountMax 10
    TCPKeepAlive yes
```

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
| 丁美霞AI视频 | ~2.3G | 有 | ❌ 超时（需拆分） |

> Gitee 免费企业版单仓库约 1G 软限制，超过会警告但通常还有 50 次推送机会。超过 2G 需升级或拆分仓库。

## 常见问题速查

| 问题 | 解决 |
|------|------|
| `Permission denied` | 检查 SSH 公钥是否添加到 Gitee |
| `LFS only supported in paid` | 使用上述 LFS 转换脚本 |
| `Operation timed out` | 配置 `ServerAliveInterval 60` |
| `exceeds quota 1024MB` | 仓库超过 1G，可继续推（有次数限制）或拆分 |
| `git lfs checkout` 后仍是 131 字节 | `.gitattributes` 缺少 LFS 规则，用脚本临时添加 |
| `git add -A` 检测不到变更 | 先 `git config --remove-section filter.lfs` |

## 关联

- [[GitHub仓库一键同步工作流]]
- [[GitHub仓库同步到Gitee镜像工作流]]
- [[../01_长期记忆/工具与环境注意事项]]
