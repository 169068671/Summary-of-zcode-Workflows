---
title: IMA Studio 查积分工作流
created: 2026-07-24
updated: 2026-07-27
tags:
  - workflow
  - workflow/ima-studio
  - ai-video
---

# IMA Studio 查积分工作流

> 2026-07-24 根据 MCP / Open API / 用户确认整理。用于回答「IMA Studio 还有多少积分」以及付费前核价。

## 名称边界

- 用户只说「ima」→ 默认**腾讯 IMA**，不走本工作流。
- 只有明确说 **IMA Studio** / imastudio / imaclaw / Nano Banana（Studio 侧）时，才查本账户积分。
- 与**拍我 AI API 积分**、**MiniMax Token Plan**、**可灵**额度完全分离，禁止混报。

## 能力边界（必须先说清）

| 要查什么 | 现状 | 做法 |
|---|---|---|
| **账户剩余积分** | 现有 MCP / 公开 Open API **没有**稳定余额接口 | 打开下方 Community 页（需登录），或请用户口述 |
| **单次/单模型积分（单价）** | 可实时查 | MCP `ima_list_models` 或视频侧 `estimate_ima_video_points` |
| **本次任务预计总消耗** | 可估算 | 单价 × 任务数（含重试预算） |

Agent **不得**：

- 编造或猜测余额数字；
- 为了「试余额」去提交付费生成任务；
- 把 Skill 文档里的旧积分表当成账户余额；
- 把过期快照当成实时余额（快照仅作参考）。

## 查余额（推荐路径）

1. 确认用户要查的是 **IMA Studio**，不是腾讯 IMA / 拍我。
2. **余额真源（用户 2026-07-24 确认）**：打开 Community 页（需已登录）：  
   [https://www.imastudio.com/community](https://www.imastudio.com/community)
3. 页面显示的剩余积分即为当前可用余额。
4. 购买 / 订阅补充入口（备用）：  
   [https://www.imaclaw.ai/imaclaw/subscription](https://www.imaclaw.ai/imaclaw/subscription)
5. API Key 管理：  
   [https://www.imaclaw.ai/imaclaw/apikey](https://www.imaclaw.ai/imaclaw/apikey)
6. 若 Zcode 无法代登：请用户打开 Community 链接，或口述当前余额后再核价。

### 余额快照（非实时）

| 时间 | 积分 | 来源 |
|---|---|---|
| 2026-07-24 | **1336** | 用户确认（community 页） |

## 查单价与预估消耗（Agent 可做）

### A. 图片 / 通用模型单价

1. MCP：`user-ima-studio` → `ima_list_models`
2. `media_type` 按需（如 `image` / `video` / `nano_banana`）
3. **必须**带对应 `task_type`（如 `text_to_image`、`image_to_image`）；缺了会报错
4. 读返回表中的 `pts` / credit_rules，作为该参数组合的实时单价

### B. 视频积分粗估

1. MCP：`user-ai-video-production` → `estimate_ima_video_points`
2. 提供 `task_type`、`model_id`、`shots`
3. 说明：这是基线估算，**正式提交仍会实时核价**；不代表账户余额

### C. 向用户汇报格式

- 模型名 + 单次积分
- 计划条数 / 镜头数
- 预计总积分 = 单价 × 条数（可加 1 次重试缓冲）
- 余额来源：网页核对 / 用户口述（写明哪一种）
- 未确认余额前，不提交付费任务

## 花钱前核对清单

1. 已区分 IMA Studio vs 其他平台积分  
2. 已实时查单价（不用过期表格）  
3. 已算预计总消耗  
4. 余额已由网页或用户确认，且 ≥ 预计总消耗  
5. 用户已明确同意扣费  
6. 提交后只保存并轮询原 `task_id`，超时不重复创建  

## 失败与信号

| 信号 | 含义 | 动作 |
|---|---|---|
| `4008 Insufficient points` | 积分不足 | 停止重试；引导 Community 核对余额，必要时再去订阅页购买；保留计划不空烧 |
| Error `6006` | 提交积分与规则不匹配 | 重新 `product/list` / `ima_list_models` 后再提交 |
| MCP 只有模型表、无余额字段 | 正常 | 改走 Community 页查余额，勿假装已查到余额 |

## 与生成流程的衔接

正式生成仍走既有 Skill / MCP（如 `ima_generate`）：先核价 → 用户确认 → 提交 → 轮询 → 记录 task_id / 实际扣费 / 本地路径。  
下载成品前按 [[../01_长期记忆/工具与环境注意事项#网络|网络说明]] 提醒处理 VPN。

## 一句话结论

**单价用 MCP 查；余额用 [imastudio.com/community](https://www.imastudio.com/community)（或用户口述）；没有余额就不要猜，也不要付费试探。**
