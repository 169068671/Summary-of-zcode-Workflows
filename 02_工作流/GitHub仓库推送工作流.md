---
title: GitHub仓库推送工作流
created: 2026-07-28
updated: 2026-07-28
status: 启用
tags:
  - workflow/general
  - git
  - github
---

# GitHub仓库推送工作流

## 目标

将本地多个 Git 仓库批量推送到 GitHub，覆盖三类需求：

- 多仓库批量推送（含 LFS 仓库）。
- GitHub 认证配置（避免明文 token 泄露）。
- 网络不稳定时的推送策略。

> 与 [[Gitee仓库同步与推送工作流]] 对称：Gitee 不支持 LFS 需转换，**GitHub 原生支持 LFS，直接推送即可**。

## 前置条件

| 步骤 | 命令/操作 | 验证 |
|------|----------|------|
| 1. 安装 gh CLI | `brew install gh` | `gh --version` |
| 2. gh 登录 | `gh auth login` | `gh auth status` 显示已登录 |
| 3. 配置 git credential helper | `gh auth setup-git` | `git config --global credential.https://github.com.helper` 非空 |
| 4. （可选）SSH 密钥 | `ssh-keygen -t ed25519` | `cat ~/.ssh/id_ed25519.pub` |

> gh CLI 是推荐入口：token 存系统 keyring，不落盘、不进 git config。

## 认证方式

### 方式 A：gh credential helper（推荐）

token 由 `gh` 管理，存系统 keyring，git 访问 GitHub 时自动调用。

```bash
# 登录 gh（首次）
gh auth login

# 配置 git 使用 gh 作为凭证助手
gh auth setup-git
```

配置后，remote URL 用**纯净 HTTPS**（不含 token）：

```
https://github.com/<用户名>/<仓库名>.git
```

验证：
```bash
git config --global credential.https://github.com.helper
# 应输出: !/opt/homebrew/bin/gh auth git-credential
```

### 方式 B：SSH 公钥

```bash
# 生成密钥（已有则跳过）
ssh-keygen -t ed25519 -C "邮箱"

# 上传公钥到 GitHub（通过 gh CLI）
gh ssh-key add ~/.ssh/id_ed25519.pub --title "wangzirui-mac-ed25519"
```

> 若 `gh ssh-key add` 报权限不足，先刷新授权：
> ```bash
> gh auth refresh -h github.com -s admin:public_key
> ```

remote URL 用 SSH 格式：
```
git@github.com:<用户名>/<仓库名>.git
```

### ⛔ 禁止：明文 token 嵌入 remote URL

**不要**这样配置 remote：
```
https://<用户名>:<token>@github.com/<用户名>/<仓库名>.git
```

token 会明文存入 `.git/config`，可能随备份/同步泄露。

**清理已有的明文 token**：
```bash
cd /Users/wangzirui/仓库名
# 改成纯净 HTTPS
git remote set-url origin https://github.com/<用户名>/<仓库名>.git
# 或改成 SSH
git remote set-url origin git@github.com:<用户名>/<仓库名>.git

# 确认 token 已清除
git remote -v | grep -o "ghp_[a-zA-Z0-9]*" && echo "⚠️ 仍有token" || echo "✅ 已清除"
```

> 清理后，若该 token 曾明文暴露，去 GitHub Settings → Developer settings → Personal access tokens **删除/轮换**它。

## 批量检查本地仓库状态

```bash
cd /Users/wangzirui
for dir in */; do
  [ -d "$dir/.git" ] || continue
  name=$(basename "$dir")
  cd "/Users/wangzirui/$name"
  # 找 github remote（可能叫 origin 或 github）
  remote_name=$(git remote | grep -E "^origin$" || git remote | grep -E "^github$" || echo "")
  lfs_count=$(git lfs ls-files 2>/dev/null | wc -l | tr -d ' ')
  dirty=$(git status --short 2>/dev/null | wc -l | tr -d ' ')
  size=$(du -sh "/Users/wangzirui/$name" 2>/dev/null | cut -f1)
  echo "$name | remote:${remote_name:-无} | LFS:$lfs_count | 改动:$dirty | 大小:$size"
  cd /Users/wangzirui
done
```

## 推送流程

### 普通仓库：直接推送

```bash
cd /Users/wangzirui/仓库名
git add -A
git commit -m "sync: 同步最新内容" 2>/dev/null || true
git push origin main
```

### LFS 仓库：直接推送（无需转换）

> **关键区别**：GitHub 原生支持 Git LFS，不需要像 Gitee 那样把指针转成真实文件。直接 `git push` 即可，LFS 对象会自动上传。

```bash
cd /Users/wangzirui/仓库名
git add -A
git commit -m "sync: 更新内容"
git push origin main
# 输出会显示: Uploading LFS objects: 100% (N/N), XX MB | X.X MB/s, done
```

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
  cd "$repo_path"

  # 找 github remote
  remote_name=$(git remote | grep -E "^origin$" || git remote | grep -E "^github$" || echo "")
  [ -z "$remote_name" ] && { echo "跳过 $name: 无 GitHub remote"; continue; }

  echo ""
  echo "=== 推送: $name ($size) ==="

  # 提交改动
  if [ -n "$(git status --porcelain)" ]; then
    git add -A
    git commit -m "sync: $name 同步" 2>/dev/null || true
  fi

  # 推送（LFS 仓库会自动上传 LFS 对象）
  git push "$remote_name" main 2>&1
  cd /Users/wangzirui
done
```

## 网络不稳定处理

GitHub 在国内访问不稳定，推送可能超时。几种应对：

### 1. 配置低速超时（避免无限挂起）

```bash
export GIT_HTTP_LOW_SPEED_LIMIT=1000   # 低于 1000 字节/秒
export GIT_HTTP_LOW_SPEED_TIME=30      # 持续 30 秒则中断
```

### 2. 重试推送

```bash
# 最多重试 3 次
for i in 1 2 3; do
  git push origin main && break
  echo "第 $i 次推送失败，5 秒后重试..."
  sleep 5
done
```

### 3. SSH 备选（HTTPS 不通时）

若 HTTPS 持续超时，改用 SSH（需先配置 SSH 公钥，见认证方式 B）：

```bash
git remote set-url origin git@github.com:<用户名>/<仓库名>.git
git push origin main
```

### 4. 大仓库分批提交

超过 500MB 的仓库，分多次小提交推送，避免单次超时：

```bash
# 先推非 LFS 小文件
git add *.md *.json *.py
git commit -m "sync: 文本文件"
git push origin main

# 再推 LFS 大文件
git add -A
git commit -m "sync: 媒体文件"
git push origin main
```

## 已验证推送记录

| 仓库 | 大小 | LFS 文件 | LFS 上传 | 状态 |
|------|------|---------|---------|------|
| 孩子们的知识点 | ~200M | 168 | 14 个 / 38MB | ✅ 成功（2026-07-28） |
| FreeCAD模型制作知识库 | ~784M | 160 | 无（删除操作） | ✅ 成功（2026-07-28） |
| 课题与论文知识库 | ~455M | 290 | 68 个 / 55MB | ✅ 成功（2026-07-28） |
| 草图设计知识库 | ~784M | 8 | 无（普通MD） | ✅ 成功（2026-07-28） |
| 教科研数据仓库 | ~38M | 2 | 无需推送 | ✅ 已同步 |
| 丁美霞AI视频 | ~2.3G | 1098 | 待测 | ⚠️ 大仓库需分批 |

> GitHub LFS 免费额度：1GB 存储 + 1GB/月 带宽。超出需购买 LFS Data Pack。

## 常见问题速查

| 问题 | 解决 |
|------|------|
| `Failed to connect to github.com port 443` | 网络波动，配置 `GIT_HTTP_LOW_SPEED_TIME` 或重试，必要时开 VPN |
| `Permission denied (publickey)` | SSH 公钥未添加到 GitHub，用 `gh ssh-key add` 上传 |
| `gh ssh-key add` 报 404 | token 权限不足，先 `gh auth refresh -h github.com -s admin:public_key` |
| remote URL 含明文 token | 改成纯净 HTTPS + `gh auth setup-git`，见认证方式 A |
| `LFS only supported in paid` | 这是 Gitee 的错误；GitHub 原生支持 LFS，不会出现 |
| LFS 上传慢/失败 | 网络问题，配置低速超时或分批推送；检查 LFS 配额 |
| 大仓库推送超时 | 分批提交（先文本后媒体），或用 SSH |

## 关联

- [[GitHub仓库一键同步工作流]]（单仓库脚本入口）
- [[Gitee仓库同步与推送工作流]]（Gitee 镜像备份，含 LFS 转换）
- [[../01_长期记忆/工具与环境注意事项]]
- [[../00_HOME/Zcode启动必读]]
