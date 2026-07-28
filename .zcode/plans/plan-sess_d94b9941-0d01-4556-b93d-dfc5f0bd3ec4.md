## 合并精简两个 Gitee 工作流，统一用本地 `mcp__gitee__*`

### 新建
`02_工作流/Gitee仓库同步与推送工作流.md`，结构：
1. 目标与适用场景（合并两份）
2. 前置条件清单（沿用表格）
3. **本地 Gitee MCP 与 git 职责边界**（新增完整对照表：25 个 `mcp__gitee__*` 工具逐行标注本工作流是否用到；明确 push/LFS 只能 git）
4. **用本地 MCP 建仓与检查**（新增，全部写成「Zcode 调 `mcp__gitee__*`」形式：list_user_repos / create_repo / get_file_content，org=dongtaishiruimoyanjingdian）
5. 批量检查本地仓库状态（shell，去重）
6. 推送流程（无 LFS 直接 push；有 LFS 用合并后的 `push_to_gitee.sh` 脚本；批量按大小排序）
7. SSH 超时配置（去重）
8. Gitee 配额注意事项（去重）
9. 实际推送记录表（沿用已验证表）
10. 常见问题速查（合并去重）
11. 关联链接

### 删除
- `02_工作流/GitHub仓库同步到Gitee镜像工作流.md`
- `02_工作流/Gitee仓库批量推送工作流.md`

### 改索引
`00_HOME/内容索引.md` 第 30-31 行两条引用合并为一条 `[[../02_工作流/Gitee仓库同步与推送工作流]]`

### 标签
`workflow/general` + `gitee` + `git` + `backup`（均已存在）

### 核验
跑 `validate_vault.py` 至 `PASS`；确认无残留断链。不动 MCP 配置文档、gitee_sync.sh、一键同步工作流。