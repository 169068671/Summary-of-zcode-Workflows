## 新建 GitHub 仓库推送工作流

### 新建
`02_工作流/GitHub仓库推送工作流.md`，结构：
1. 目标与适用场景（多仓库推送、LFS、认证配置）
2. 前置条件（SSH/gh CLI）
3. 认证方式：A) gh credential helper（推荐）B) SSH 公钥；禁止明文 token（含清理方法）
4. 批量检查本地仓库状态（shell）
5. 推送流程：普通仓库直接 push；LFS 仓库 GitHub 原生支持直接 push（无需转换，区别于 Gitee）；批量推送脚本
6. 网络不稳定处理（GIT_HTTP_LOW_SPEED_LIMIT、重试、SSH 备选）
7. 已验证仓库记录表（含今天 4 个仓库 + LFS 上传量）
8. 常见问题速查（明文 token 清理、LFS 配额、publickey 错误）
9. 关联链接

### 索引与标签
- `00_HOME/内容索引.md` 工作流小节新增一条
- `00_HOME/标签索引.md` 新增 `github` 标签
- 文档标签：`workflow/general` + `git` + `github`

### 不改
一键同步工作流、Gitee 工作流、gitee_sync.sh 均不动。

### 核验
跑 `validate_vault.py` 至 PASS。