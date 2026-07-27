---
title: OpenRouter HappyHorse 丁美霞视频工作流
created: 2026-07-17
updated: 2026-07-27
status: verified
tags:
  - workflow/ai-video
  - workflow/openrouter-video
  - quality/expression
  - quality/skin
  - quality/face
---

# OpenRouter HappyHorse 丁美霞视频工作流

> [!success] 已验证结论
> OpenRouter `alibaba/happyhorse-1.1` 使用丁美霞主锚点做单张首帧图生视频，人物、动作和镜头效果较好，可作为后续同类竖屏生活方式镜头的优先工作流。正式调用前仍必须实时查询模型能力和价格。

> [!danger] 双图强制核验（2026-07-18 用户确认）
> 以后制作丁美霞视频，必须同时用 [[../01_长期记忆/重要人物与数字资产#双图核验清单（必用）|4K 主锚点 + 脸型核验 8 格]] 做关键帧与成片验收。脸偏胖、圆脸、双下巴不合格，须重做。

## 固定输入

- 人物必须使用 [[../01_长期记忆/重要人物与数字资产#唯一主锚点（不变）|丁美霞原 4K 主锚点]] 作为第一参考和唯一身份来源。
- **必须同时挂载** [[../01_长期记忆/重要人物与数字资产#脸型核验图（非锚点，必对照）|脸型核验 8 格]]：只校准瘦削椭圆脸与下颌轮廓，不提供新身份。
- 根据分镜从 [[../01_长期记忆/丁美霞状态参考体系]] 选择辅助状态：S08 校准微笑，S01/S07/S08 校准皮肤，S02–S07 校准端杯与啜饮动作。
- 状态截帧与脸型 8 格都没有完整锚点数据，不得单独作为首帧用来生成新脸。
- 对仅接受一张首帧的视频模型，先用原 4K 主锚点 + 脸型 8 格（+ 选定状态）生成并审核场景关键帧，再将已批准关键帧用于图生视频。
- 首帧内容只做分辨率和文件体积适配，不重新生成人脸。
- 720P 竖屏项目优先把主锚点等比例转为 `720×1280` 的高质量 JPEG 副本，减少 Base64 上传时的网络中断。

## 提交前预检

1. 查询 OpenRouter 当前视频模型目录，确认模型 ID、时长、分辨率、画幅和价格。
2. 查询当前账户可用额度，计算预计费用。
3. 核对输入首帧像素尺寸、画幅、文件大小和可读性。
4. 检查项目目录是否已存在任务 ID；已有任务时禁止重复提交。
5. 确认本地已准备好双图核验文件（4K 主锚点 + 脸型 8 格），关键帧审核清单里有“身份 / 脸型”两栏。

## 推荐生成方式

- 模型：`alibaba/happyhorse-1.1`（动态信息，每次重新核对）。
- 模式：`frame_images` 单张 `first_frame`。
- 竖屏：`aspect_ratio: 9:16`。
- 试片：优先 720P；构图、人物和动作通过后，再根据需求决定是否提高分辨率。
- 动作：单镜头只设计一个主要动作，拆成起势、执行、落点和余韵。
- 镜头：稳定缓慢运镜，避免角度突变、快速推拉或无动机跳切。

## 丁美霞笑容控制硬规则

> [!danger] 不可违反
> 丁美霞的默认笑容必须是克制、自然的微笑。不得生成咧嘴笑、露齿大笑、张嘴笑或笑容强度持续放大。

### 正向表情描述

- 以状态参考 S08 中的笑容为幅度上限，不得比 S08 笑得更大。
- 嘴角只轻微上扬，幅度约为完全放松表情到大笑之间的 10%–15%。
- 双唇自然闭合或几乎闭合，默认不露齿。
- 面颊与眼周保持放松，不夸张挤眼，不形成过深的笑纹。
- 笑容只是情绪微变化，不改变脸型、五官比例或视觉年龄。
- 如果分镜不需要笑，保持平静、友好的中性表情，不让模型自行添加笑容。

### 必须写入的反向约束

`no grin, no broad smile, no open-mouth smile, no laughter, no visible teeth, no exaggerated cheek lifting, no squinting from laughter, no escalating smile intensity, no frozen smile`

### 可直接复用的提示词片段

`She maintains a restrained, natural micro-smile: the corners of her mouth rise only slightly, her lips remain gently closed, no teeth are visible, her cheeks and eye area stay relaxed, and the smile intensity remains subtle and constant throughout. Preserve her exact facial identity and visual age.`

### 皮肤控制提示词片段

`Use the approved state references S01, S07 and S08 only to match the healthy skin state: naturally firm, luminous and even-toned skin; clean under-eye area; subtle authentic fine skin texture; no eye bags, deep tear troughs, sagging, deep wrinkles, fatigue, ageing drift, waxy skin, plastic smoothing or beauty-filter look. The original 4K anchor remains the only identity source.`

### 脸型控制提示词片段

`Reference 2 (coffee 8-grid) locks face slimness only: slim oval face, defined jawline, slightly hollow cheeks, slender chin and neck exactly as Reference 2; absolutely no round face, wide face, chubby cheeks, double chin or facial weight gain. Do not blend or average faces.`

### 推近 / 特写皮肤硬规则

> [!danger] 不可只验首帧
> 只要镜头包含推近、变焦、人物走近镜头或最终落到半身 / 面部特写，就必须单独检查**推近后的近景帧**。首帧皮肤合格但近景出现松弛，整镜仍判定不合格。

生成提示词必须明确：

`Throughout the dolly-in and final close-up, keep her skin naturally firm, youthful, luminous and even-toned with clean under-eyes. No sagging cheeks, loose jawline, jowls, eye bags, deep tear troughs, deep nasolabial folds, neck wrinkles, fatigue or ageing drift. Preserve subtle authentic skin texture; no waxy or plastic smoothing.`

验收至少抽取：

1. 推近开始帧（基准）。
2. 推近 50% 的中间帧。
3. 推近 80% 的近景帧。
4. 最终最接近镜头的尾帧。

四帧均对照 S01、S07、S08，重点检查：

- 脸颊是否下垂或突然变厚。
- 下颌线是否变松、出现嘴边肉或双下巴。
- 眼下是否新增眼袋、泪沟或疲态。
- 法令纹、颈纹、皱纹是否随推近突然加深。
- 肤色与纹理是否自然；不得用过度磨皮掩盖松弛。

### 说话镜头例外

说话时允许正常口型开合，但基础表情仍为平静或微笑；句间不露齿咧嘴笑，不因对嘴型而变成大笑。

## 异步任务与下载

1. 只提交一次，立即保存任务 ID 和轮询地址。
2. 网络响应慢时继续等待原请求，在任务状态和计费未明前不再次提交。
3. 原图上传中断时，对比中断前后余额、查询任务记录，确认未计费后才允许用适配首帧重试。
4. 生成完成后立即下载到本地，保存实际费用和媒体规格。

## 验收

1. 检查实际分辨率、时长、帧率、编码和音轨。
2. 每 2–3 秒抽帧，并重点检查开头、表情转换点和结尾；推近 / 特写镜头必须额外抽取推近开始、50%、80% 和最终近景帧。
3. **双图人物验收**：开头、中间和结尾人脸必须同时对照原 4K 主锚点（身份/五官/眼镜/发型）与脸型核验 8 格（瘦削度/下颌线）；偏胖、圆脸、双下巴不合格。
4. 皮肤验收：对照状态参考 S01、S07、S08 检查紧致度、肤色、眼下、真实纹理和高光；尤其检查推近后的近景与尾帧。出现眼袋、泪沟加深、脸颊/下颌/颈部松弛、法令纹或皱纹加深、过度磨皮、肤色漂移或视觉年龄变老时判定为不合格。
5. 表情验收：微笑幅度不得超过状态参考 S08；只要出现露齿、张嘴笑、咧嘴笑、大笑、夸张挤眼或笑容逐渐放大，该镜头判定为不合格。
6. 物理验收：手指、握持、杯具、液体、接触、影子和物体恒存正常。
7. 不合格时优先修改身份、皮肤、表情提示词和动作节拍，只补做问题镜头。

## 已验证样例

- 任务 ID：`TRJDU4ihm9E7VhE9EO5V`
- 输出：720×1280，24fps，约 15.16 秒，包含音轨。
- 实际费用：USD 1.482（2026-07-16 记录，不作为未来固定报价）。
- 成片：`/Users/wangzirui/Documents/视频/丁美霞_喝咖啡_OpenRouter_HappyHorse1.1_2026-07-16/output/丁美霞_咖啡厅喝咖啡_HappyHorse1.1_720P_15s.mp4`
- 经验：人物、饮咖啡动作和慢推镜较好；结尾笑容幅度偏大，后续必须使用本页的微笑硬规则。
