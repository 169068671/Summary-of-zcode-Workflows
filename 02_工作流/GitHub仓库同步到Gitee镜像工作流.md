---
title: GitHub仓库同步到Gitee镜像工作流
created: 2026-07-28
updated: 2026-07-28
status: 启用
tags:
  - workflow/general
---

# GitHub仓库同步到Gitee镜像工作流

## 目标

将本地 Obsidian 知识库（GitHub 远程）批量添加 Gitee 镜像远程，并将所有内容推送到 Gitee，作为 GitHub 的备份。适用于 GitHub 访问不稳定时的备用方案。

## 前置条件

1. Gitee 企业/组织已创建（如 `dongtaishiruimoyanjingdian`）。
2. Gitee 仓库已创建（与 GitHub 仓库同名或按规则命名）。
3. SSH 公钥已添加到 Gitee 账户（`git@gitee.com` 免密推送）。
4. 本地仓库的 `.git/config` 中已配置 Gitee remote。

## 适用场景

- GitHub 访问不稳定，需要国内镜像备份。
- 给所有 Obsidian 知识库添加 Gitee 双远程。
- Git LFS 文件需要转换为普通文件后推送到 Gitee（Gitee 免费版不支持 LFS）。

## 快速命令

### 1. 批量检查所有仓库的 Gitee remote 状态

```bash
cd /Users/wangzirui
for dir in */; do
  if [ -d "$dir/.git" ]; then
    name=$(basename "$dir")
    has_gitee=$(git -C "$dir" remote -v 2>/dev/null | grep -i gitee | head -1)
    has_github=$(git -C "$dir" remote -v 2>/dev/null | grep -i github | head -1)
    status=()
    [ -n "$has_gitee" ] && status+=("Gitee")
    [ -n "$has_github" ] && status+=("GitHub")
    echo "$name: ${status[*]:-无 remote}"
  fi
done
```

### 2. 检查本地与 Gitee 的同步状态

```bash
cd /Users/wangzirui/仓库名
local_hash=$(git rev-parse HEAD)
remote_hash=$(git ls-remote gitee HEAD 2>/dev/null | awk '{print $1}')
if [ "$local_hash" = "$remote_hash" ]; then
  echo "已同步"
elif [ -z "$remote_hash" ]; then
  echo "Gitee 为空"
else
  echo "不同步"
fi
```

### 3. 单个仓库推送到 Gitee（无 LFS 文件）

```bash
cd /Users/wangzirui/仓库名
git add -A
git commit -m "sync: 同步最新内容" 2>/dev/null || true
git push gitee main
```

## 含 Git LFS 文件的仓库推送

### 为什么需要特殊处理

Gitee 免费版/基础版**不支持 Git LFS**。如果仓库中有 LFS 跟踪的文件，直接推送会报错：

```
Permission to 'xxx' denied
Message: LFS only supported repository in paid or trial enterprise.
```

解决方案：将 LFS 指针文件临时转换为**真实文件内容**，推送到 Gitee，然后本地恢复 LFS 指针。

### 关键步骤

#### 步骤 1：临时添加 LFS 跟踪规则（让 `git lfs checkout` 生效）

某些仓库的 `.gitattributes` 中**没有 LFS 跟踪规则**（只有排除规则），导致 `git lfs checkout` 无法检出真实文件。需要先临时添加规则：

```bash
cd /Users/wangzirui/仓库名
git checkout -b gitee-temp

echo "*.png filter=lfs diff=lfs merge=lfs -text" >> .gitattributes
echo "*.jpg filter=lfs diff=lfs merge=lfs -text" >> .gitattributes
echo "*.mp4 filter=lfs diff=lfs merge=lfs -text" >> .gitattributes
# ... 根据仓库实际文件类型添加更多规则

git add .gitattributes
git commit -m "临时添加LFS规则"
```

#### 步骤 2：检出 LFS 真实文件

```bash
git lfs checkout
```

#### 步骤 3：完全移除 LFS filter 配置（关键！）

如果不移除 filter，后续 `git add` 时会通过 clean filter 把真实文件**又转回 LFS 指针**：

```bash
git config --local --remove-section filter.lfs 2>/dev/null || true
git config --global --remove-section filter.lfs 2>/dev/null || true
```

#### 步骤 4：恢复原始 `.gitattributes` 并重新添加文件

```bash
# 恢复原始 .gitattributes（不含 LFS 规则）
git show main:.gitattributes > .gitattributes 2>/dev/null || rm -f .gitattributes

# 重新添加所有文件（此时没有 clean filter，真实内容进入索引）
git add -A
```

> **如果 `git add -A` 后仍检测不到变更**，使用强制刷新：
> ```bash
> git add --renormalize .
> ```

#### 步骤 5：提交并推送

```bash
git commit -m "Gitee推送: 转换LFS为普通文件"
git push gitee gitee-temp:main --force
```

#### 步骤 6：清理——切回原分支并恢复 LFS

```bash
git checkout main
git branch -D gitee-temp
git lfs install
git lfs checkout
```

### 完整脚本（单仓库）

```bash
#!/bin/bash
REPO_PATH="/Users/wangzirui/仓库名"
cd "$REPO_PATH" || exit 1

# 确保工作区干净
if [ -n "$(git status --porcelain)" ]; then
  git add -A && git commit -m "sync: 同步最新内容" 2>/dev/null || true
fi

CURRENT=$(git branch --show-current)
git checkout -b gitee-temp

# 临时添加 LFS 规则
cat >> .gitattributes << 'EOF'
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
EOF
git add .gitattributes && git commit -m "临时添加LFS规则"

# 检出真实文件
git lfs checkout

# 完全移除 LFS filter
git config --local --remove-section filter.lfs 2>/dev/null || true
git config --global --remove-section filter.lfs 2>/dev/null || true

# 恢复原始 .gitattributes
git show "$CURRENT":.gitattributes > .gitattributes 2>/dev/null || rm -f .gitattributes

# 强制重新添加（关键步骤）
git add --renormalize .
git add -A

# 提交并推送
git commit -m "Gitee推送: 转换LFS为普通文件"
git push gitee gitee-temp:main --force

# 恢复
git checkout "$CURRENT"
git branch -D gitee-temp
git lfs install
git lfs checkout
```

## 批量推送所有仓库

按仓库大小从小到大排序推送，避免大仓库阻塞：

```bash
cd /Users/wangzirui
for dir in */; do
  [ -d "$dir/.git" ] || continue
  name=$(basename "$dir")
  size=$(du -sh "$dir" 2>/dev/null | cut -f1)
  echo "$size $name"
done | sort -h | while read -r size name; do
  echo "=== 推送: $name ($size) ==="
  if [ -d "/Users/wangzirui/$name/.git" ]; then
    # 检测是否有 LFS 文件
    lfs_count=$(cd "/Users/wangzirui/$name" && git lfs ls-files 2>/dev/null | wc -l | tr -d ' ')
    if [ "$lfs_count" -gt 0 ]; then
      echo "有 $lfs_count 个 LFS 文件，使用 LFS 转换脚本..."
      # 调用上面的单仓库脚本
    else
      echo "无 LFS 文件，直接推送..."
      cd "/Users/wangzirui/$name" && git push gitee main 2>&1
    fi
  fi
  echo ""
done
```

## SSH 超时配置

大仓库推送时 SSH 连接可能超时，在 `~/.ssh/config` 中添加：

```
Host gitee.com
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

- 超过 1GB 的仓库推送时会出现 `exceeds quota 1024MB` 警告，但通常还有 **50 次推送机会**。
- 若仓库超过 2G/3G，需升级到对应付费套餐，或只推送小文件（Markdown、配置等），大文件留在 GitHub LFS。

## 常见问题

### Q: `git lfs checkout` 后文件仍是 LFS 指针（131 字节）？
A: `.gitattributes` 中没有 LFS 跟踪规则，只有排除规则。临时添加规则后再执行 `git lfs checkout`。

### Q: `git add -A` 后检测不到 LFS 文件变更？
A: LFS 的 clean filter 仍在生效。需要先 `git config --remove-section filter.lfs`，再 `git add --renormalize .`。

### Q: 推送时出现 `Operation timed out`？
A: 仓库太大，SSH 连接超时。配置 `ServerAliveInterval`，或分多次小提交推送。

### Q: Gitee 上已经有旧内容，怎么强制覆盖？
A: 使用 `git push gitee <分支>:main --force`。

## 关联

- [[GitHub仓库一键同步工作流]]
- [[../01_长期记忆/工具与环境注意事项]]
- [[../00_HOME/Zcode启动必读]]
