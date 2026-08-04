---
title: 扫描乐谱PDF转可编辑乐谱工作流-Zcode版
created: 2026-08-01
updated: 2026-08-01
type: workflow
record_type: workflow
status: active
version: 1.1.0
owner: Zcode
source: "从 Codex 工作流汇总迁入改造"
tags:
  - workflow/documents
---
# 扫描乐谱 PDF 转可编辑乐谱工作流-Zcode版

> [!important] 工作流目标
> 将扫描版乐谱 PDF 转换为可在 MuseScore 等软件中编辑的 MusicXML（`.mxl`）和 MuseScore（`.mscz`）文件，并将歌词转换为挂接在旋律音符上的标准 `<lyric>` 对象。全程保留原谱参照，区分机器识别结果与人工校订结论。

## 一句话调用

> 按“扫描乐谱 PDF 转可编辑乐谱工作流”处理这份 PDF；先做一首完整样曲，输出 MXL、MSCZ 和可视化预览，歌词必须为标准 `<lyric>` 对象，通过验收后再决定是否批量处理全书。

## 适用范围

### 适合

- 纸质乐谱的扫描 PDF。
- 钢琴大谱表、独奏谱、带歌词的流行歌曲谱。
- 需要后续移调、改编、分谱、播放或重新排版的乐谱。

### 不宜直接批量自动处理

- 扫描歪斜、透页、乐谱裁边或分辨率过低。
- 手写谱、自由节拍、极复杂多声部或现代记谱。
- 原稿受版权或使用范围限制，未明确数字化用途。

## 标准交付包

| 文件 | 作用 | 是否必须 |
|---|---|---|
| `曲名_可编辑初稿.mxl` | 跨软件交换、结构核验 | 是 |
| `曲名_可编辑初稿.mscz` | MuseScore 内编辑 | 是 |
| `曲名_可编辑初稿_预览.pdf` | 视觉校对与打印预览 | 是 |
| `曲名_原谱参考.pdf` | 回到扫描原件复核 | 是 |
| `曲名_Audiveris工程.omr` | 保留 OMR 中间结果 | 建议 |
| `曲名_复核记录.md` | 记录误差、修正和人工核验状态 | 批量任务必须 |

## 工具和环境

| 工具 | 用途 |
|---|---|
| Poppler（`pdfinfo`、`pdftoppm`） | PDF 结构检查、页面渲染 |
| `qpdf` | PDF 结构完整性检查 |
| `img2pdf` | 将拆分后的乐谱图片无损封装为 PDF |
| Audiveris | 乐谱 OMR 识别，输出 `.omr` 和 `.mxl` |
| Tesseract 兼容语言数据 | Audiveris 文字和歌词 OCR |
| MuseScore | 导入 MusicXML，生成 `.mscz` 和预览 PDF |
| Python XML/ZIP 脚本 | 清理 MusicXML、转换歌词对象、结构统计 |

> [!warning] 下载和安装
> 优先使用官方发布页。使用镜像下载时，必须用官方发布页的 SHA-256 或签名校验安装包，不以“能安装”代替来源校验。

## 总流程

```mermaid
flowchart LR
    A["原始扫描 PDF"] --> B["结构与版权检查"]
    B --> C["定位曲目与拆页"]
    C --> D["单曲样张 OMR"]
    D --> E["MusicXML 结构清理"]
    E --> F["歌词转标准 lyric 对象"]
    F --> G["MuseScore 导入与排版"]
    G --> H["结构+视觉+听感复核"]
    H --> I{"样张通过？"}
    I -- "是" --> J["批量处理"]
    I -- "否" --> K["调整参数或人工录入"]
```

## 阶段 0：接收与原件保护

### 操作

1. 记录原文件绝对路径、文件大小、页数和修改时间。
2. 原始 PDF 只读使用，不覆盖、不重新压缩。
3. 明确乐谱来源、版权状态和数字化用途。
4. 所有中间文件写入 `tmp/pdfs/<任务名>/`，最终文件写入 `output/score/<曲名>/`。

### 阶段门 G0

- [ ] 原件可读且已保留。
- [ ] 使用范围明确。
- [ ] 输出与临时目录不会覆盖原件。

## 阶段 1：PDF 结构与页面检查

### 基础检查

```bash
pdfinfo "原始乐谱.pdf"
qpdf --check "原始乐谱.pdf"
pdftoppm -f 1 -singlefile -png -r 120 "原始乐谱.pdf" "tmp/pdfs/任务名/首页"
```

### 必查项

- PDF 总页数和页面尺寸。
- 是否有可搜索文本层；没有文本层不影响 OMR，但不得将普通 OCR 当作乐谱识别。
- 是否一个 PDF 页面并排了两个书页。
- 谱表线、调号、拍号、连线和歌词是否清晰。

### 阶段门 G1

- [ ] PDF 结构无致命错误。
- [ ] 至少一页已渲染为 PNG 并人工查看。
- [ ] 已判断单页、双页或需要旋转/校正。

## 阶段 2：定位曲目、渲染与拆页

1. 先用目录、页码或低分辨率缩略图定位曲目。
2. 以 300 dpi 渲染目标 PDF 页面。
3. 双页并排时，按中缝拆分为两张完整书页。
4. 逐张检查页眉、谱表、左右边缘和底部是否被裁切。
5. 用 `img2pdf` 将分页图片封装为“原谱参考 PDF”。

> [!warning] 不可只依赖自动中分
> 书脊阴影、边框和扫描偏移都可能使几何中心不等于真实中缝。拆页后必须视觉检查。

### 阶段门 G2

- [ ] 选定曲目的所有页面完整。
- [ ] 无谱表、音符、歌词或反复记号被裁掉。
- [ ] 原谱参考 PDF 页序正确。

## 阶段 3：单曲样张 OMR

### 原则

- 先处理一首包含标题、双手谱表、歌词、指法、连线和反复记号的完整曲目。
- 样张未通过验收前，不批量运行全书。

### Audiveris 无界面运行示例（macOS）

```bash
TESSDATA_PREFIX="/兼容tessdata目录" \
"/Applications/Audiveris.app/Contents/runtime/Contents/Home/bin/java" \
  -Djava.awt.headless=true \
  --add-exports=java.desktop/sun.awt.image=ALL-UNNAMED \
  --enable-native-access=ALL-UNNAMED \
  -Dfile.encoding=UTF-8 -Xms512m -Xmx8G \
  -cp "/Applications/Audiveris.app/Contents/app/*" \
  Audiveris -batch -export -save -output "输出目录" "原谱参考.pdf"
```

> [!note] Tesseract 兼容性
> Audiveris 某些版本会调用 Tesseract legacy OCR。如日志提示语言数据仅支持 LSTM，需改用同时含 legacy 与 LSTM 组件的 `traineddata`，并用 `combine_tessdata -d` 确认组件，不应跳过日志警告。

### 保留信息

- Audiveris 版本。
- 输入页码与渲染分辨率。
- 原始 `.omr`、`.mxl` 和日志。
- 原始小节数、识别小节数、节奏警告和 OCR 警告。

### 阶段门 G3

- [ ] `.omr` 和 `.mxl` 成功生成。
- [ ] 日志中的节奏、小节和 OCR 警告已记录。
- [ ] 不把“成功导出”等同于“音符正确”。

## 阶段 4：MusicXML 结构清理

Audiveris 可能将指法、小节号和歌词碎片误识别为页级 `<credit>`，导致 MuseScore 导入后出现空白页或浮动文字。

### 清理项

1. 校正 `movement-title`、作者和来源元数据。
2. 仅保留确认属于标题、艺术家和词曲作者的页级 `<credit>`。
3. 删除由指法、小节号、歌词碎片造成的伪 `<credit>`。
4. 保留 MusicXML DOCTYPE、ZIP 容器结构和 `META-INF/container.xml`。
5. 清理后执行 `unzip -t` 和 XML 解析检查。

### 阶段门 G4

- [ ] MXL ZIP 容器完整。
- [ ] XML 可正常解析。
- [ ] 标题和作者元数据正确。
- [ ] 不存在明显的伪页级 credit。

## 阶段 5：将歌词转换为标准 `<lyric>` 对象

### 为什么必须转换

OMR 常把歌词识别为 `<direction><direction-type><words>`。这类文本只是乐谱上的浮动标签，不能随旋律音符移动、不能正确处理音节，也不是 MuseScore 的可编辑歌词。

### 转换规则

1. 识别含字母的 `words` 文本；排除速度语、纯数字指法和小节号。
2. 根据 MusicXML 流中的 `note`、`backup`、`forward`、`duration` 和 `offset` 计算文本的乐谱时间位置。
3. 默认挂接到上方谱表、主旋律声部的非休止音；具体为 `staff=1` 和 `voice=1`，曲谱结构不同时必须调整。
4. 一个和弦只选择一个起始音符挂接歌词，不向和弦内所有音符重复添加。
5. 普通单词写入 `<lyric number="1"><text>...</text></lyric>`。
6. 含连字符的词拆分为音节，使用 `<syllabic>begin</syllabic>`、`middle` 和 `end`。
7. 只修正能回到原谱确认的 OCR 粘连或错字；无法确认时保留原识别文本并标记待核。
8. 转换成功后删除已对应的旧方向文本，避免歌词重复显示。

### 结构检查示例

```python
import zipfile
from xml.etree import ElementTree as ET

with zipfile.ZipFile("score.mxl") as archive:
    name = next(
        item for item in archive.namelist()
        if item.endswith((".xml", ".musicxml")) and "container" not in item
    )
    root = ET.fromstring(archive.read(name))
    print("lyric objects:", len(root.findall(".//lyric")))
    print("lyric text nodes:", len(root.findall(".//lyric/text")))
    print("remaining words:", [
        (node.text or "").strip()
        for node in root.findall(".//direction-type/words")
    ])
```

### 阶段门 G5

- [ ] 歌词不再仅以方向文本存在。
- [ ] `<lyric>` 和 `<lyric/text>` 数量大于 0 且相等。
- [ ] 速度语、指法和小节号没有被转为歌词。
- [ ] 抽查首句、跨小节句和连字音节的挂接位置。

## 阶段 6：MuseScore 导入与输出

1. 用 MuseScore 导入清理后的 `.mxl`。
2. 保存为 `.mscz`。
3. 导出预览 PDF。
4. 不直接覆盖 MXL；MXL 与 MSCZ 同时保留。

### macOS 注意事项

- MuseScore 命令行导入/导出仍可能短暂启动图形界面。
- 一个转换命令只启动一次，不并发重复调用。
- 确认文件已生成后，如进程不退出，只终止本次启动的具体 MuseScore 进程，不使用宽泛的全局杀进程命令。
- 后续验证使用 `unzip`、`qpdf`、`pdfinfo` 和页面渲染，避免反复打开软件。

### 阶段门 G6

- [ ] MXL 和 MSCZ 都能解压且容器无错。
- [ ] 预览 PDF 成功生成。
- [ ] 导出页数合理，无伪 credit 造成的空白页。

## 阶段 7：三层验收

### A. 结构验收

```bash
unzip -t "曲名_可编辑初稿.mxl"
unzip -t "曲名_可编辑初稿.mscz"
qpdf --check "曲名_可编辑初稿_预览.pdf"
pdfinfo "曲名_可编辑初稿_预览.pdf"
```

统计项：

- 小节数、音符数、谱表数和声部。
- `<lyric>` 数、剩余方向文本。
- 标题、作者、页数和文件大小。

### B. 视觉验收

```bash
pdftoppm -png -r 120 "曲名_可编辑初稿_预览.pdf" "tmp/pdfs/任务名/验收/page"
```

逐页检查：

- 谱号、调号、拍号、小节线和反复记号。
- 音高、时值、附点、连线、休止符和临时升降号。
- 左右手分配、声部归属和跨谱表记号。
- 歌词是否挂在正确旋律音符上，是否有重复、粘连、越界或过度拥挤。
- 标题、作者、系统间距和换页是否合理。

### C. 听感验收

- 在 MuseScore 中低速播放。
- 重点听节奏警告小节、切分、弱起、跨小节延音和反复段。
- 听感检查只用于发现异常，最终修正必须回到原谱确认。

### 样张完成门 G7

- [ ] 所有交付文件通过结构检查。
- [ ] 预览 PDF 每一页都已渲染并视觉检查。
- [ ] 已列出所有已知节奏、音符和歌词问题。
- [ ] 交付状态标明为“自动识别初稿”或“人工校订完成”。
- [ ] 只有样张通过后才能进入全书批量。

## 批量处理规则

1. 按曲目分批，不把整本书直接合并成一个超大 MSCZ。
2. 每首曲单独保留原谱参考 PDF、MXL、MSCZ 和复核状态。
3. 识别参数、软件版本和歌词挂接声部必须固定并记录。
4. 任意一首出现系统性错误时，暂停后续批处理，先修正流程或参数。
5. 不对未经人工核验的全书使用“转换完成”标记。

## 建议目录结构

```text
output/score/
└── 曲名/
    ├── 曲名_原谱参考.pdf
    ├── 曲名_Audiveris工程.omr
    ├── 曲名_可编辑初稿.mxl
    ├── 曲名_可编辑初稿.mscz
    ├── 曲名_可编辑初稿_预览.pdf
    └── 曲名_复核记录.md
```

## 常见故障与处理

| 现象 | 可能原因 | 处理 |
|---|---|---|
| Audiveris 图形启动器崩溃 | macOS/AWT 兼容问题 | 改用内置 Java 的 headless 批处理命令 |
| OCR 报不支持 legacy 引擎 | `traineddata` 仅含 LSTM | 换用兼容语言数据并检查组件 |
| MuseScore 多出空白页 | 伪页级 `<credit>` | 清理 credit 后重新导入 |
| 歌词看得见但不可编辑 | 歌词是 direction words | 按乐谱时间转换为 `<lyric>` |
| 歌词挂在错误手部 | 旋律不在 `staff=1, voice=1` | 先确认旋律声部，再重新挂接 |
| 歌词挤成一团 | 音符间距小或拆词错误 | 校正音节、增加小节宽度或调整系统换行 |
| 小节时值过长/过短 | 连音、附点、休止或声部识别错 | 回到原谱逐音校正，不用自动填充掩盖 |
| MuseScore 命令后软件反复弹出 | 命令行调用依赖 GUI 或进程未退出 | 串行执行一次，文件生成后终止具体残留进程，后续只做静态验证 |

## 质量和证据边界

| 内容 | 状态定义 |
|---|---|
| 扫描原谱 | 原始事实参照 |
| Audiveris/MuseScore 输出 | 机器生成的可编辑初稿 |
| 脚本修正 | 基于规则的自动处理，仍需人工核对 |
| 人工逐小节比对 | 可记录为已校订 |
| 仅听感无异常 | 不等于逐符号校订完成 |

> [!important] 完成口径
> “可编辑初稿已生成”可在结构和预览验收后使用；“乐谱转换完成”只能在音符、节奏、记号和歌词逐小节人工复核后使用。

## 实例验证（2026-08-01）

本工作流已用扫描乐谱中的 `Hey Jude` 双页样曲验证：

- 已生成可编辑 MXL 和 MSCZ。
- 51 个歌词文本片段被转换为 127 个标准 `<lyric>` 对象。
- 速度语和纯数字指法被保留为非歌词对象。
- 预览 PDF 为 2 页，结构检查通过，无空白中间页。
- 结果仍标记为“自动识别初稿”；已知节奏警告和歌词间距需人工复核。

## 任务结束检查表

- [ ] 原始 PDF 未被修改。
- [ ] 样曲的 MXL、MSCZ、预览 PDF 和原谱参考已保留。
- [ ] MXL/MSCZ 容器、XML 和 PDF 结构已验证。
- [ ] 预览 PDF 所有页已渲染检查。
- [ ] 歌词为标准 `<lyric>` 对象，非歌词文本未误转。
- [ ] 已知错误、节奏警告和人工待办已写入复核记录。
- [ ] 临时文件已整理；只保留复现和复核必需的中间产物。
