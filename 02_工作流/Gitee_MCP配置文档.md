---
title: Gitee MCP 配置与使用文档
created: 2026-07-28
updated: 2026-07-28
status: 启用
tags:
  - workflow/general
  - gitee
  - mcp
---

# Gitee MCP 配置与使用详细文档

> 创建日期: 2026-07-28
> 适用环境: macOS (Apple Silicon) + TRAE SOLO CN

---

## 目录

1. [概述](#概述)
2. [远程 Gitee MCP（推荐 TRAE SOLO 使用）](#远程-gitee-mcp推荐-trae-solo-使用)
3. [本地 Gitee MCP（命令行使用）](#本地-gitee-mcp命令行使用)
4. [TRAE SOLO 中调用本地 MCP 的变通方案](#trae-solo-中调用本地-mcp-的变通方案)
5. [可用工具列表（25 个）](#可用工具列表25-个)
6. [常用调用示例](#常用调用示例)
7. [故障排查](#故障排查)

---

## 概述

Gitee MCP Server 是 Gitee 官方提供的模型上下文协议（Model Context Protocol, MCP）服务器实现，使 AI 助手能够通过标准化接口管理 Gitee 仓库、Issue、Pull Request 等。

**两种使用方式：**

| 方式 | 适用场景 | TRAE SOLO 兼容 | 命令行可用 |
|------|----------|----------------|-----------|
| 远程 MCP | TRAE SOLO 集成 | 原生支持 | 支持 |
| 本地 MCP | 命令行脚本 | 需变通（见第4节） | 原生支持 |

---

## 远程 Gitee MCP（推荐 TRAE SOLO 使用）

### 基本信息

- **远程服务器 URL**: `https://api.gitee.com/mcp`
- **协议**: HTTP/SSE
- **认证方式**: Bearer Token（Gitee 个人访问令牌）
- **无需安装任何软件**，直接通过网络调用

### 获取 Gitee 个人访问令牌

1. 访问 https://gitee.com/profile/personal_access_tokens
2. 点击「生成新令牌」
3. 勾选需要的权限范围（建议全选）
4. 复制生成的 token（格式类似 `3c6d7040879c2485010d8a7df9134305`）

### TRAE SOLO 配置

编辑 TRAE SOLO 的 `settings.json` 文件：

**文件路径（macOS）**：
```
/Users/<用户名>/Library/Application Support/TRAE SOLO CN/User/settings.json
```

**配置内容**：
```json
{
    "mcpServers": {
        "gitee": {
            "url": "https://api.gitee.com/mcp",
            "headers": {
                "Authorization": "Bearer <你的Gitee个人访问令牌>"
            }
        }
    }
}
```

### 配置步骤

1. 打开 TRAE SOLO
2. 按 `Cmd + Shift + P` 打开命令面板
3. 搜索 `Preferences: Open Settings (JSON)`
4. 在 `settings.json` 中添加上述 `mcpServers` 配置
5. 保存文件
6. **重启 TRAE SOLO** 使配置生效

### 远程 MCP 优缺点

**优点**：
- 零安装，开箱即用
- TRAE SOLO 原生支持
- 自动维护，无需更新

**缺点**：
- 依赖网络连接
- 无法自定义工具集（除非使用请求头过滤）

### 请求头工具过滤（可选）

远程 MCP 支持通过 HTTP 请求头动态过滤可用工具：

```json
{
    "mcpServers": {
        "gitee": {
            "url": "https://api.gitee.com/mcp",
            "headers": {
                "Authorization": "Bearer <token>",
                "X-MCP-Enabled-Tools": "list_user_repos,get_file_content,list_repo_issues"
            }
        }
    }
}
```

- `X-MCP-Enabled-Tools`: 白名单模式，仅启用列出的工具
- `X-MCP-Disabled-Tools`: 黑名单模式，禁用列出的工具

---

## 本地 Gitee MCP（命令行使用）

### 基本信息

- **二进制路径**: `~/.local/bin/mcp-gitee`
- **传输模式**: stdio（默认）、http、sse
- **源码仓库**: `https://gitee.com/oschina/mcp-gitee`
- **Go 版本要求**: 1.23.0 或更高

### 安装步骤

#### 1. 安装 Go 环境

```bash
brew install go
```

验证安装：
```bash
go version
# 输出示例: go version go1.26.5 darwin/arm64
```

#### 2. 克隆仓库

```bash
cd /tmp
git clone https://gitee.com/oschina/mcp-gitee.git
cd mcp-gitee
```

#### 3. 编译构建

> **国内网络注意**：默认 Go 代理可能超时，需使用国内镜像。

```bash
GOPROXY=https://goproxy.cn,direct make build
```

构建成功后输出：
```
🤖🤖 Build Success 🤖🤖
Executable path: /tmp/mcp-gitee/bin/mcp-gitee
```

#### 4. 安装到系统路径

```bash
mkdir -p ~/.local/bin
cp /tmp/mcp-gitee/bin/mcp-gitee ~/.local/bin/
chmod +x ~/.local/bin/mcp-gitee
```

#### 5. 验证安装

```bash
~/.local/bin/mcp-gitee --version
# 输出: Gitee MCP Server / Version: 1.0.0
```

### 命令行选项

| 选项 | 环境变量 | 说明 |
|------|----------|------|
| `--token=<token>` | `GITEE_ACCESS_TOKEN` | Gitee 访问令牌 |
| `--api-base=<url>` | `GITEE_API_BASE` | API 基础 URL（默认: https://gitee.com/api/v5） |
| `--version` | - | 显示版本信息 |
| `--transport=<type>` | - | 传输类型：stdio、sse、http（默认: stdio） |
| `--address=<host:port>` | - | 服务器地址（默认: localhost:8000） |
| `--enabled-toolsets=<list>` | `ENABLED_TOOLSETS` | 启用指定工具（逗号分隔） |
| `--disabled-toolsets=<list>` | `DISABLED_TOOLSETS` | 禁用指定工具（逗号分隔） |

### 本地 MCP 优缺点

**优点**：
- 可自定义工具集
- 支持 stdio/http/sse 多种传输模式
- 响应速度可能更快

**缺点**：
- 需要安装 Go 环境并编译
- TRAE SOLO 不原生支持本地 stdio 模式
- 需手动维护更新

---

## TRAE SOLO 中调用本地 MCP 的变通方案

### 问题说明

TRAE SOLO 的 MCP 集成仅支持**远程 URL 模式**，不支持本地 stdio 模式（`"command": "..."`）。这意味着直接在 `settings.json` 中配置 `"command": "/Users/.../mcp-gitee"` 是无效的。

### 变通方案：启动本地 HTTP/SSE 服务器

#### 步骤 1：启动本地 MCP 服务器

```bash
# HTTP 模式
~/.local/bin/mcp-gitee --token=<你的token> --transport=http --address=localhost:8000 &

# 或 SSE 模式
~/.local/bin/mcp-gitee --token=<你的token> --transport=sse --address=localhost:8000 &
```

#### 步骤 2：配置 TRAE SOLO

编辑 `settings.json`：

```json
{
    "mcpServers": {
        "gitee": {
            "url": "http://localhost:8000/mcp",
            "headers": {
                "Authorization": "Bearer <你的token>"
            }
        }
    }
}
```

#### 步骤 3：重启 TRAE SOLO

保存配置后重启 TRAE SOLO，即可通过本地服务器调用 Gitee MCP。

> 注意：每次重启电脑后需要重新启动本地 MCP 服务器。可以创建 launchd 服务实现开机自启。

### 推荐方案

| 场景 | 推荐方案 |
|------|----------|
| TRAE SOLO 集成 | 远程 MCP `https://api.gitee.com/mcp` |
| 命令行脚本 | 本地 stdio 模式 |
| 离线开发 | 本地 HTTP 服务器 |
| 需要自定义工具集 | 本地 MCP + `--enabled-toolsets` |

---

## 可用工具列表（25 个）

### 仓库管理（9 个）

| 工具名 | 说明 |
|--------|------|
| `list_user_repos` | 列出用户授权的仓库 |
| `get_file_content` | 获取仓库中文件的内容 |
| `create_repo` | 创建仓库（个人、组织或企业） |
| `fork_repository` | Fork 仓库 |
| `create_release` | 为仓库创建发行版 |
| `list_releases` | 列出仓库发行版 |
| `search_open_source_repositories` | 搜索开源仓库 |
| `search_files_by_content` | 在仓库中按内容搜索文件 |
| `compare_branches_tags` | 对比两个分支、Tag 或提交的差异 |

### Pull Request（8 个）

| 工具名 | 说明 |
|--------|------|
| `list_repo_pulls` | 列出仓库中的拉取请求 |
| `merge_pull` | 合并拉取请求 |
| `create_pull` | 创建拉取请求 |
| `update_pull` | 更新拉取请求 |
| `get_pull_detail` | 获取拉取请求的详细信息 |
| `get_diff_files` | 获取拉取请求的差异文件 |
| `manage_pull_review` | 管理拉取请求审查（通过或取消） |
| `create_comment` | 评论 Issue 或拉取请求 |

### Issue（5 个）

| 工具名 | 说明 |
|--------|------|
| `create_issue` | 创建 Issue |
| `update_issue` | 更新 Issue |
| `get_repo_issue_detail` | 获取仓库 Issue 的详细信息 |
| `list_repo_issues` | 列出仓库 Issue |
| `list_comments` | 列出 Issue 或拉取请求的所有评论 |

### 用户与通知（3 个）

| 工具名 | 说明 |
|--------|------|
| `get_user_info` | 获取当前认证用户信息 |
| `search_users` | 搜索用户 |
| `list_user_notifications` | 列出用户通知 |

---

## 常用调用示例

### 1. 远程 MCP（curl）

#### 列出所有工具
```bash
curl -s -X POST "https://api.gitee.com/mcp" \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","id":1,"method":"tools/list","params":{}}'
```

#### 获取用户信息
```bash
curl -s -X POST "https://api.gitee.com/mcp" \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","id":2,"method":"tools/call","params":{"name":"get_user_info","arguments":{}}}'
```

#### 列出企业版仓库
```bash
curl -s -X POST "https://api.gitee.com/mcp" \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","id":3,"method":"tools/call","params":{"name":"list_user_repos","arguments":{"affiliation":"enterprise_member","page":1,"per_page":100}}}'
```

#### 获取仓库文件内容
```bash
curl -s -X POST "https://api.gitee.com/mcp" \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","id":4,"method":"tools/call","params":{"name":"get_file_content","arguments":{"owner":"dongtaishiruimoyanjingdian","repo":"Zcode-Workflow-Summary","path":"README.md"}}}'
```

### 2. 本地 MCP（stdio 模式）

#### 列出所有工具
```bash
echo '{"jsonrpc":"2.0","id":1,"method":"tools/list","params":{}}' \
  | ~/.local/bin/mcp-gitee --token=<token>
```

#### 获取用户信息
```bash
echo '{"jsonrpc":"2.0","id":2,"method":"tools/call","params":{"name":"get_user_info","arguments":{}}}' \
  | ~/.local/bin/mcp-gitee --token=<token>
```

#### 列出企业版仓库（带格式化输出）
```bash
echo '{"jsonrpc":"2.0","id":3,"method":"tools/call","params":{"name":"list_user_repos","arguments":{"affiliation":"enterprise_member","page":1,"per_page":100}}}' \
  | ~/.local/bin/mcp-gitee --token=<token> 2>/dev/null \
  | python3 -c "
import sys, json
data = json.load(sys.stdin)
content = data.get('result', {}).get('content', [])
for item in content:
    if item.get('type') == 'text':
        repos = json.loads(item.get('text', '[]'))
        print(f'共 {len(repos)} 个仓库')
        for r in repos:
            print(f'  - {r.get(\"human_name\", \"?\")}')
"
```

#### 创建 Issue
```bash
echo '{"jsonrpc":"2.0","id":4,"method":"tools/call","params":{"name":"create_issue","arguments":{"owner":"dongtaishiruimoyanjingdian","repo":"Zcode-Workflow-Summary","title":"测试Issue","body":"这是一个通过MCP创建的测试Issue"}}}' \
  | ~/.local/bin/mcp-gitee --token=<token>
```

### 3. 本地 MCP（HTTP 模式）

启动服务器：
```bash
~/.local/bin/mcp-gitee --token=<token> --transport=http --address=localhost:8000 &
```

调用（与远程方式相同，URL 改为 localhost）：
```bash
curl -s -X POST "http://localhost:8000/mcp" \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","id":1,"method":"tools/list","params":{}}'
```

---

## 故障排查

### 1. Go 编译超时

**问题**：`dial tcp 142.250.198.81:443: i/o timeout`

**解决**：使用国内 Go 代理
```bash
GOPROXY=https://goproxy.cn,direct make build
```

### 2. TRAE SOLO 无法识别本地 MCP

**问题**：配置了 `"command": "..."` 但 TRAE SOLO 不加载

**原因**：TRAE SOLO 仅支持远程 URL 模式

**解决**：使用远程 MCP，或启动本地 HTTP 服务器（见第4节）

### 3. Token 无效或权限不足

**问题**：API 返回 401 或 403 错误

**解决**：
1. 访问 https://gitee.com/profile/personal_access_tokens 重新生成
2. 确保勾选了所需权限
3. 更新 `settings.json` 或命令行 `--token` 参数

### 4. 远程 MCP 返回数据解析错误

**问题**：Python 解析 JSON 时报 `'list' object has no attribute 'get'`

**原因**：`list_user_repos` 返回的 `content[0].text` 直接是 JSON 数组（不是 `{"data": [...]}`）

**解决**：
```python
inner = json.loads(content[0]['text'])
repos = inner if isinstance(inner, list) else inner.get('data', [])
```

### 5. 企业版仓库查询参数冲突

**问题**：`422 If you specify visibility or affiliation, you cannot specify type`

**解决**：不要同时传 `type` 和 `affiliation` 参数，只使用 `affiliation`：
```json
{"affiliation": "enterprise_member", "page": 1, "per_page": 100}
```

---

## 附录

### 相关链接

- Gitee MCP 源码: https://gitee.com/oschina/mcp-gitee
- Gitee 个人访问令牌: https://gitee.com/profile/personal_access_tokens
- TRAE 官方文档: https://docs.trae.cn/
- MCP 协议规范: https://modelcontextprotocol.io/

### 当前配置信息

| 配置项 | 值 |
|--------|-----|
| Gitee 用户名 | wanghj_dz (wanghjdz) |
| 企业版组织 | 东台市睿墨眼镜店 (dongtaishiruimoyanjingdian) |
| 企业版仓库数 | 32 个（全部私有） |
| 本地 MCP 路径 | `~/.local/bin/mcp-gitee` |
| 本地 MCP 版本 | 1.0.0 |
| Go 版本 | 1.26.5 |
| 远程 MCP URL | `https://api.gitee.com/mcp` |
| 可用工具数 | 25 个 |

### Zcode 本地 MCP 挂载（stdio 模式）

除 TRAE SOLO 使用远程 MCP 外，本地 `mcp-gitee` 二进制也以 stdio 模式挂载到 Zcode，使 Zcode 会话可直接调用 `mcp__gitee__*` 工具。

**配置位置**：`~/.zcode/cli/config.json` → `mcp.servers.gitee`

```json
{
    "type": "stdio",
    "command": "/Users/wangzirui/.local/bin/mcp-gitee",
    "args": [
        "--token=<你的Gitee个人访问令牌>"
    ],
    "cwd": "/Users/wangzirui",
    "enabled": true,
    "timeoutMs": 600000
}
```

**生效方式**：MCP server 在 Zcode 启动时加载，新增或修改后需**重启 Zcode / 新开会话**才会出现在工具列表中。

**已验证**（2026-07-28）：
- `initialize` 握手成功，serverInfo = `mcp-gitee v1.0.0`。
- `tools/list` 返回 25 个工具。
- `tools/call` → `get_user_info` 返回用户 `wanghjdz`，链路完整。

> 安全提示：token 以明文写入 `config.json`（本地文件，不进 git）。如需更高安全性，可改用环境变量 `GITEE_ACCESS_TOKEN` 并在 shell profile 中导出，`args` 中省略 `--token`。
