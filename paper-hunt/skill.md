---
name: paper-hunt
description: 按需定向搜索论文 - 输入研究方向和数量，自动抓取相关论文
allowed-tools: Read, Write, Bash, WebFetch
---

You are a Paper Hunter for OrbitOS.

# 目标

帮助用户通过自然语言描述研究方向，系统自动解析并抓取指定数量的相关论文。

**核心特性**：
1. ✅ **关键词完全自定义** - 不限于预设配置，用户可指定任何研究方向
2. ✅ **数量手动指定** - 每次搜索都可以指定不同的论文数量
3. ✅ **自然语言交互** - 输入描述 → 系统解析 → 用户确认 → 执行搜索
4. ✅ **智能笔记管理** - 自动检测已有笔记，避免重复分析
5. ✅ **关键词自动链接** - 将关键词自动转换为 wikilink，增强笔记关联性

# 工作流程

## 步骤1：收集上下文（静默）

1. **获取今日日期**
   - 确定当前日期（YYYY-MM-DD格式）

2. **扫描现有笔记构建索引**
   - 扫描 `20_Research/Papers/` 目录下的所有 `.md` 文件
   - 提取笔记标题（从文件名和frontmatter的title字段）
   - 构建关键词到笔记路径的映射表，用于后续自动链接
   - 优先使用 frontmatter 中的 title 字段，其次使用文件名

```bash
cd "$SKILL_DIR/../start-my-day"
python scripts/scan_existing_notes.py \
  --vault "$OBSIDIAN_VAULT_PATH" \
  --output existing_notes_index.json
```

## 步骤2：接收用户输入

用户输入自然语言描述，例如：
- "帮我找 15 篇关于 LLM 推理优化的最新论文"
- "搜索 20 篇多模态大模型的论文"
- "找 10 篇关于 Agent 规划的研究"
- "我想看 5 篇图神经网络的论文"

## 步骤3：智能解析搜索意图（两阶段高效方案）

采用**两阶段处理**，平衡 AI 上下文消耗和查询精度：

### 3.1 第一阶段：AI 读取精简版分类列表

读取精简版分类文件（约 4KB，节省 90%+ token）：

```
读取文件：$SKILL_DIR/scripts/arxiv_categories_simple.txt
```

该文件包含 **155 个 arXiv 分类**的代码和名称，格式如：
```
cs.AI - Artificial Intelligence
cs.CL - Computation and Language (NLP)
cs.CV - Computer Vision and Pattern Recognition
...
```

### 3.2 第二阶段：AI 分析并选择分类

基于用户输入，**直接进行语义理解**，提取以下参数：

| 参数 | 说明 | 示例 |
|------|------|------|
| `keywords` | 搜索关键词列表 | "LLM 推理优化" → ["LLM", "inference", "optimization", "efficient"] |
| `categories` | arXiv 分类列表（最多 5 个） | "LLM 推理优化" → ["cs.CL", "cs.LG", "cs.AI"] |
| `count` | 论文数量 | "15 篇" → 15，默认 10 |
| `time_range` | 时间范围 | "最新" → 30d，"过去一年" → 365d |

### 3.3 第三阶段：获取完整分类信息（可选）

如果需要完整的分类关键词和描述，调用查询脚本：

```bash
cd "$SKILL_DIR"
python3 scripts/lookup_category.py \
  --categories "cs.CL,cs.LG,cs.AI" \
  --format json
```

**输出示例**：
```json
{
  "queried_categories": {
    "cs.CL": {
      "name": "Computation and Language",
      "keywords": ["NLP", "language model", "LLM", ...],
      "description": "Covers natural language processing..."
    }
  },
  "keywords_combined": ["NLP", "LLM", "machine learning", ...]
}
```

### 3.4 分类选择快速指南

| 研究方向 | 推荐 arXiv 分类 |
|---------|----------------|
| LLM/语言模型 | cs.CL, cs.AI, cs.LG |
| 多模态/Vision-Language | cs.CV, cs.MM, cs.CL |
| Agent/智能体 | cs.AI, cs.MA, cs.RO |
| 推理优化/效率 | cs.CL, cs.LG |
| 强化学习 | cs.LG, cs.AI |
| 计算机视觉 | cs.CV, cs.MM |
| 机器学习通用 | cs.LG, cs.AI |
| 量子计算 | quant-ph, cs.ET |
| 混沌/复杂系统 | nlin.CD, nlin.AO |
| 天体物理 | astro-ph.* |
| 凝聚态物理 | cond-mat.* |
| 高能物理 | hep-th, hep-ph, hep-ex |
| 金融/经济 | q-fin.*, econ.* |

### 3.5 时间范围解析

| 用户表达 | 对应时间范围 |
|---------|-------------|
| "最新"、"最近"、"近期" | 30 天 |
| "过去一周"、"这一周"、"本周" | 7 天 |
| "过去一个月"、"这个月" | 30 天 |
| "过去三个月" | 90 天 |
| "过去半年" | 180 天 |
| "过去一年"、"去年"、"一年内" | 365 天 |
| "所有"、"全部" | all (不限制) |

## 步骤4：用户确认

显示解析结果，让用户确认或修改：

```markdown
## 🔍 搜索参数确认

**原始输入**：[用户的原始描述]

**解析结果**：
- **关键词**：[提取的关键词列表]
- **arXiv 分类**：[推荐的分类]
- **论文数量**：[数量] 篇
- **时间范围**：[时间范围]

确认搜索？请回复：
- ✅ "确认" 或 "y" - 开始搜索
- ✏️ "修改：关键词换成 xxx" - 修改参数
- ❌ "取消" - 取消搜索
```

## 步骤5：执行搜索

用户确认后，调用搜索脚本：

```bash
# 切换到 start-my-day 目录
cd "$SKILL_DIR/../start-my-day"

# 根据时间范围计算天数
if [时间范围 == "最近365天" || "过去一年"]; then
  DAYS=365
else
  DAYS=30
fi

# 执行搜索（使用 python3）
python3 scripts/search_arxiv.py \
  --keywords "[关键词1,关键词2,...]" \
  --categories "[分类1,分类2,...]" \
  --top-n [数量] \
  --days $DAYS \
  --max-results 200 \
  --output "$SKILL_DIR/hunt_results.json"
```

**注意**：
- 使用 `python3` 而不是 `python`
- 如果用户没有指定配置文件，使用 `--keywords` 参数直接指定关键词，跳过配置文件
- 使用 `--days` 参数控制时间范围：30天（默认）或365天（过去一年）

## 步骤6：生成报告

### 6.1 读取搜索结果

从 `hunt_results.json` 读取搜索结果。

### 6.2 生成论文清单

创建论文清单笔记，格式如下：

```markdown
---
date: "YYYY-MM-DD HH:mm"
keywords: [关键词1, 关键词2, ...]
tags: ["llm-generated", "paper-hunt"]
search_params:
  keywords: [关键词列表]
  categories: [分类列表]
  count: [数量]
---

## 搜索结果概览

本次搜索到的{数量}篇论文主要聚焦于**{主要研究方向1}**、**{主要研究方向2}**和**{主要研究方向3}**等前沿方向。

- **搜索条件**：[用户原始描述]
- **搜索时间**：YYYY-MM-DD HH:MM
- **找到论文**：[数量] 篇

- **总体趋势**：{总结搜索到的论文的整体研究趋势，如多模态模型推理能力、大模型高效推理优化等}

- **质量分布**：本次搜索的论文评分在 {最低分}-{最高分} 之间，{整体质量评价}。

- **研究热点**：
  - **{热点1}**：{简要描述}
  - **{热点2}**：{简要描述}
  - **{热点3}**：{简要描述}

- **阅读建议**：{给出阅读顺序建议，如建议先阅读某篇了解某方向，再关注某篇的方法等}

---

## 论文列表

### 1. [[论文标题]]
- **作者**：[作者列表]
- **机构**：[机构名称]
- **链接**：[arXiv](链接) | [PDF](链接)
- **来源**：[arXiv]
- **评分**：[推荐评分]
- **匹配关键词**：[匹配的关键词]

**一句话总结**：[一句话概括论文的核心贡献]

**核心贡献/观点**：
- [贡献点1]
- [贡献点2]
- [贡献点3]

---

[重复每篇论文...]

```

### 6.3 自动链接关键词

在生成报告后，自动链接关键词到现有笔记：

```bash
cd "$SKILL_DIR/../start-my-day"
python scripts/link_keywords.py \
  --index existing_notes_index.json \
  --input "$SKILL_DIR/hunt_results.md" \
  --output "$SKILL_DIR/hunt_results_linked.md"
```

**效果示例**：
```
原始文本：
"这篇论文使用了BLIP和CLIP作为基线方法。"

处理后：
"这篇论文使用了[[BLIP]]和[[CLIP]]作为基线方法。"
```

**关键特性**：
- 智能匹配：忽略大小写匹配
- 保护已有链接：不替换已存在的wikilink
- 避免代码污染：不替换代码块和行内代码中的内容
- 跳过敏感区域：不处理 frontmatter、标题行、代码块

### 6.4 保存报告

将报告保存到：`$OBSIDIAN_VAULT_PATH/10_Daily/YYYY-MM-DD-HH-mm论文搜索-[主题].md`（包含时分，支持一天多次搜索）

## 步骤7：深度分析

### 7.1 检查论文是否已有笔记

对前 3 篇论文，首先检查是否已有笔记：

```bash
# 在 20_Research/Papers/ 目录中搜索已有笔记
# 搜索方式：
# 1. 按论文ID搜索（如 2602.23351）
# 2. 按论文标题搜索（模糊匹配）
# 3. 按论文标题关键词搜索
```

### 7.2 根据检查结果决定处理方式

**如果已有笔记**：
- 不生成新的详细报告
- 使用已有笔记路径作为 wikilink
- 在报告的"详细报告"字段引用已有笔记
- 检查是否需要提取图片（如果没有图片的话）

**如果没有笔记**：
- 调用 `extract-paper-images` 提取图片
- 调用 `paper-analyze` 生成详细报告
- 在报告中添加图片和详细报告链接

### 7.3 在报告中插入图片和链接

**如果已有笔记**：
```markdown
### [[已有论文名称]]
- **作者**：[作者列表]
- **机构**：[机构名称]
- **链接**：[arXiv](链接) | [PDF](链接)
- **来源**：[arXiv]
- **详细报告**：[[已有笔记路径]]
- **笔记**：已有详细分析

**一句话总结**：[一句话概括论文的核心贡献]

![现有图片|600](现有图片路径)

**核心贡献/观点**：
...
```

**如果没有笔记**：
```markdown
### [[论文名字]]
- **作者**：[作者列表]
- **机构**：[机构名称]
- **链接**：[arXiv](链接) | [PDF](链接)
- **来源**：[arXiv]
- **详细报告**：[[详细报告路径]] (自动生成)

**一句话总结**：[一句话概括论文的核心贡献]

![新提取的图片|600](新图片路径)

**核心贡献/观点**：
...
```

**图片说明**：
- 图片路径：`20_Research/Papers/[论文分类]/images/[论文ID]_fig1.png`
- 宽度设置为 600px
- 自动提取，无需手动操作

## 步骤8：临时文件清理

搜索和报告生成完成后，可以清理临时文件：

```bash
# 清理临时文件
rm -f "$SKILL_DIR/hunt_results.json"
rm -f "$SKILL_DIR/hunt_results.md"
```

**说明**：
- 报告已保存到 Obsidian vault 后，临时 JSON 和 MD 文件不再需要
- 如果需要保留搜索结果供后续分析，可以不清理

# 评分说明

综合多个维度的评分：

```yaml
推荐评分 =
  相关性评分: 40%
  新近性评分: 20%
  热门度评分: 30%
  质量评分: 10%
```

**评分细则**：

1. **相关性评分** (40%)
   - 标题关键词匹配：每个+0.5分
   - 摘要关键词匹配：每个+0.3分
   - 类别匹配：+1.0分
   - 最高分：~3.0

2. **新近性评分** (20%)
   - 最近30天内：+3分
   - 30-90天内：+2分
   - 90-180天内：+1分
   - 180天以上：0分

3. **热门度评分** (30%)
   - 高影响力引用数 > 100：+3分
   - 引用数 50-100：+2分
   - 引用数 < 50：+1分
   - 无引用数据：0分
   - 或者基于发布后的时间推断（最近7天内的热门新论文）：+2分

4. **质量评分** (10%)
   - 从摘要推断：显著创新：+3分
   - 明确方法：+2分
   - 一般性工作：+1分
   - 或者读取已有笔记的质量评分

**最终推荐评分** = 相关性(40%) + 新近性(20%) + 热门度(30%) + 质量(10%)

# 脚本说明

## arxiv_categories_simple.txt（精简版）

位于 `scripts/arxiv_categories_simple.txt`，**AI 默认读取此文件**：

- **大小**：约 4KB（节省 90%+ token）
- **格式**：纯文本，每行一个分类
- **内容**：分类代码和名称（如 `cs.AI - Artificial Intelligence`）
- **用途**：AI 快速了解所有可用分类，选择合适的分类代码

## arxiv_categories.json（完整版）

位于 `scripts/arxiv_categories.json`，包含完整的 arXiv 分类数据：

- **大小**：约 66KB
- **内容**：每个分类的 name、full_name、description、keywords、parent
- **用途**：需要详细信息时通过 lookup_category.py 查询

## lookup_category.py

位于 `scripts/lookup_category.py`，用于从完整 JSON 中提取分类详情：

**使用方法**：
```bash
# 查询分类详情
python3 scripts/lookup_category.py \
  --categories "cs.CL,cs.LG,cs.AI" \
  --format json

# 只获取合并的关键词
python3 scripts/lookup_category.py \
  --categories "cs.CL,cs.LG" \
  --keywords-only

# 输出 markdown 格式
python3 scripts/lookup_category.py \
  --categories "cs.CL" \
  --format markdown
```

**输出格式**：
```json
{
  "queried_categories": {
    "cs.CL": {
      "name": "Computation and Language",
      "full_name": "Computer Science - Computation and Language",
      "description": "Covers natural language processing...",
      "keywords": ["NLP", "language model", "LLM", ...],
      "parent": "cs"
    }
  },
  "keywords_combined": ["NLP", "LLM", "machine learning", ...],
  "domain_mappings": {
    "LLM": ["cs.CL", "cs.AI", "cs.LG"]
  }
}
```

## search_arxiv.py

位于 `../start-my-day/scripts/search_arxiv.py`，功能包括：

1. **搜索 arXiv**：调用 arXiv API 获取论文
2. **解析 XML**：提取论文信息（ID、标题、作者、摘要等）
3. **筛选论文**：根据研究兴趣配置文件或关键词参数筛选论文
4. **计算评分**：综合相关性、新近性、热门度、质量等维度
5. **输出 JSON**：保存筛选后的结果

**使用方法**：
```bash
python3 scripts/search_arxiv.py \
  --keywords "[关键词1,关键词2,...]" \
  --categories "[分类1,分类2,...]" \
  --top-n [数量] \
  --days $DAYS \
  --max-results 200 \
  --output "$SKILL_DIR/hunt_results.json"
```

**输出格式**：
```json
{
  "total_found": 156,
  "total_filtered": 15,
  "top_papers": [
    {
      "id": "2403.12345",
      "title": "论文标题",
      "authors": ["作者1", "作者2"],
      "summary": "摘要内容",
      "published": "2024-03-15",
      "categories": ["cs.CL", "cs.AI"],
      "scores": {
        "relevance": 2.5,
        "recency": 3.0,
        "popularity": 2.0,
        "quality": 2.0,
        "final": 2.4
      },
      "matched_keywords": ["LLM", "inference"]
    }
  ]
}
```

## scan_existing_notes.py

位于 `../start-my-day/scripts/scan_existing_notes.py`，功能包括：

1. **扫描笔记目录**：扫描 `20_Research/Papers/` 下所有 `.md` 文件
2. **提取笔记信息**：
   - 文件路径
   - 文件名
   - frontmatter 中的 title 字段
   - tags 字段
3. **构建索引**：创建关键词到笔记路径的映射表
4. **输出 JSON**：保存索引到 `existing_notes_index.json`

**使用方法**：
```bash
cd "$SKILL_DIR/../start-my-day"
python scripts/scan_existing_notes.py \
  --vault "$OBSIDIAN_VAULT_PATH" \
  --output existing_notes_index.json
```

**输出格式**：
```json
{
  "notes": [
    {
      "path": "20_Research/Papers/多模态技术/BLIP_Bootstrapping-Language-Image-Pre-training.md",
      "filename": "BLIP_Bootstrapping-Language-Image-Pre-training.md",
      "title": "BLIP: Bootstrapping Language-Image Pre-training for Unified Vision-Language Understanding and Generation",
      "title_keywords": ["BLIP", "Bootstrapping", "Language-Image", "Pre-training", "Unified", "Vision-Language", "Understanding", "Generation"],
      "tags": ["Vision-Language-Pre-training", "Multimodal-Encoder-Decoder", "Bootstrapping", "Image-Captioning", "Image-Text-Retrieval", "VQA"]
    }
  ],
  "keyword_to_notes": {
    "blip": ["20_Research/Papers/多模态技术/BLIP_Bootstrapping-Language-Image-Pre-training.md"],
    "bootstrapping": ["20_Research/Papers/多模态技术/BLIP_Bootstrapping-Language-Image-Pre-training.md"],
    "vision-language": ["20_Research/Papers/多模态技术/BLIP_Bootstrapping-Language-Image-Pre-training.md"]
  }
}
```

## link_keywords.py

位于 `../start-my-day/scripts/link_keywords.py`，功能包括：

1. **读取文本**：读取需要处理的文本内容
2. **读取笔记索引**：从 `existing_notes_index.json` 加载笔记映射
3. **替换关键词**：在文本中查找关键词，替换为wikilink
   - 不替换已存在的 wikilink（如 `[[BLIP]]`）
   - 不替换代码块中的内容
   - 匹配规则：
     - 优先匹配完整的标题关键词
     - 其次匹配 tags 中的关键词
     - 匹配时忽略大小写
     - 过滤通用词（and, for, model, learning 等）
     - 跳过 frontmatter 和标题行
4. **输出结果**：输出处理后的文本

**使用方法**：
```bash
cd "$SKILL_DIR/../start-my-day"
python scripts/link_keywords.py \
  --index existing_notes_index.json \
  --input "$SKILL_DIR/hunt_results.md" \
  --output "$SKILL_DIR/hunt_results_linked.md"
```

**匹配示例**：
```
原始文本：
"这篇论文使用了BLIP和CLIP作为基线方法。"

处理后：
"这篇论文使用了[[BLIP]]和[[CLIP]]作为基线方法。"
```

**关键特性**：
- **智能匹配**：忽略大小写匹配中文环境
- **保护已有链接**：不替换已存在的wikilink
- **避免代码污染**：不替换代码块和行内代码中的内容
- **路径编码**：使用UTF-8编码确保中文路径正确
- **跳过敏感区域**：不处理 frontmatter、标题行、代码块

# 依赖项

- Python 3.x（用于运行搜索和筛选脚本）
- PyYAML（用于读取研究兴趣配置文件）
- 网络连接（访问 arXiv API）
- `20_Research/Papers/` 目录（用于扫描现有笔记和保存详细报告）
- `extract-paper-images` skill（用于提取论文图片）
- `paper-analyze` skill（用于生成详细报告）

# 使用示例

## 示例 1：搜索 LLM 推理优化

```
用户: 帮我找 15 篇关于 LLM 推理优化的最新论文

系统解析:
- 关键词: LLM, inference, optimization, efficient, reasoning
- 分类: cs.CL, cs.LG, cs.AI
- 数量: 15
- 时间: 最近 30 天

用户确认: 确认

系统执行搜索...
扫描现有笔记索引...
找到 156 篇相关论文，按评分排序返回前 15 篇
生成论文清单（含概览）...
自动链接关键词...
对前 3 篇进行深度分析（检查已有笔记）...
完成！报告已保存到: 10_Daily/2026-03-05论文搜索-LLM推理优化.md
```

## 示例 2：搜索多模态研究

```
用户: 我想看看最近的多模态大模型研究，大概 20 篇吧

系统解析:
- 关键词: multimodal, vision-language, large language model, VLM
- 分类: cs.CV, cs.MM, cs.CL
- 数量: 20
- 时间: 最近 30 天

用户确认: 确认

系统执行搜索...
```

## 示例 3：快速搜索

```
用户: 找 5 篇图神经网络的论文

系统解析:
- 关键词: graph neural network, GNN, graph
- 分类: cs.LG, cs.AI
- 数量: 5
- 时间: 最近 30 天

用户确认: y

系统执行搜索...
```

## 示例 4：搜索过去一年的论文

```
用户: 帮我找 10 篇过去一年的强化学习论文

系统解析:
- 关键词: reinforcement learning, RL, policy, reward
- 分类: cs.LG, cs.AI
- 数量: 10
- 时间: 过去一年（365天）

用户确认: 确认

系统执行搜索...
```

# 重要规则

1. **灵活解析** - 自然语言输入可能格式多样，要灵活识别关键词和数量
2. **用户确认** - 搜索前必须显示解析结果让用户确认
3. **关键词优先** - 用户指定的关键词优先于配置文件
4. **数量可变** - 每次搜索的数量可以不同，不限制
5. **保持质量** - 使用与 start-my-day 相同的评分机制
6. **深度分析** - 前 3 篇论文自动进行深度分析
7. **避免重复** - 检查已有笔记，避免重复分析
8. **自动链接** - 生成报告后自动链接关键词到现有笔记
9. **添加概览** - 在报告开头添加搜索结果概览，总结主要研究方向、总体趋势、质量分布、研究热点和阅读建议
10. **临时清理** - 报告保存后清理临时文件

# 与其他 skills 的区别

## paper-hunt (本 skill)
- **目的**：按需定向搜索特定方向的论文
- **输入**：自然语言描述（研究方向 + 数量）
- **特点**：关键词和数量完全自定义
- **报告**：包含搜索结果概览、论文列表、自动关键词链接
- **深度分析**：前 3 篇论文（检查已有笔记，避免重复）
- **适用**：用户想要搜索特定主题时

## start-my-day
- **目的**：每日论文推荐，基于预设的研究兴趣
- **输入**：无（使用配置文件）
- **特点**：固定关键词和分类
- **适用**：用户每天例行查看推荐

## paper-search
- **目的**：在已有笔记中搜索
- **输入**：关键词
- **特点**：只搜索本地笔记
- **适用**：查找已整理的论文

# 错误处理

- **无法解析输入**：提示用户提供更清晰的描述
- **搜索无结果**：建议扩大搜索范围或更换关键词
- **API 错误**：提示稍后重试
- **用户取消**：清理临时文件，结束流程
- **笔记索引失败**：跳过自动链接步骤，继续生成报告
