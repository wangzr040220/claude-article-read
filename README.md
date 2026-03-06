# claude-article-read

[中文文档](README_CN.md)

> Interactive paper search, recommendation, analysis, and organization directly in Claude Code

## Introduction

This is a collection of Claude Code Skills for automating the workflow of searching, recommending, analyzing, and organizing research papers. By calling arXiv and Semantic Scholar APIs, it recommends high-quality papers daily and automatically generates detailed notes and relationship graphs.

## Features

### 1. start-my-day - Daily Paper Recommendation
- Search papers from arXiv for the last month
- Search high-popularity papers from Semantic Scholar for the past year
- Comprehensive scoring based on four dimensions: relevance, recency, popularity, and quality
- Auto-generate daily overview and recommendation list
- Auto-generate detailed analysis and extract images for top 3 papers
- Auto-link keywords to existing notes

### 2. paper-hunt - On-Demand Targeted Paper Search
- **Natural Language Input**: Describe your research direction in natural language, e.g., "Find 15 recent papers about LLM inference optimization"
- **Fully Customizable Keywords**: Not limited to preset configurations, specify different keywords each time
- **Manual Quantity Specification**: Specify different paper quantities for each search
- **Intelligent Parsing**: AI automatically parses search intent and recommends appropriate arXiv categories
- **User Confirmation Mechanism**: Display parsed results before search, execute after user confirmation
- **Smart Note Management**: Automatically detect existing notes to avoid duplicate analysis
- **Auto Keyword Linking**: Automatically convert keywords to wikilinks for enhanced note connectivity

### 3. paper-analyze - Deep Paper Analysis
- Deep analysis of single paper
- Generate structured notes including:
  - Abstract translation and key points extraction
  - Research background and motivation
  - Method overview and architecture
  - Experimental results analysis
  - Research value assessment
  - Advantages and limitations analysis
  - Comparison with related papers
- Auto-extract paper images and insert into notes
- Update knowledge graph

### 4. extract-paper-images - Paper Image Extraction
- Prioritize extracting high-quality images from arXiv source packages
- Support extracting images from PDF as fallback
- Auto-generate image index
- Save to images subdirectory in notes directory

### 5. paper-search - Paper Note Search
- Search papers in existing notes
- Support search by title, author, keywords, domain
- Relevance score sorting

## Installation

### Prerequisites

1. **Claude Code CLI** - Need to install and configure Claude Code
2. **Python 3.8+** - For running search and analysis scripts
3. **Dependencies**:
   ```bash
   # Normal installation
   pip install -r requirements.txt
   
   # If encountering PEP 668 error (macOS Homebrew Python), use:
   pip install --break-system-packages -r requirements.txt
   
   # Or use virtual environment (recommended)
   python3 -m venv .venv
   source .venv/bin/activate  # macOS/Linux
   # .venv\Scripts\activate  # Windows
   pip install -r requirements.txt
   ```

### Installation Steps

1. Clone or copy this repository to your Claude Code skills directory:
   ```bash
   # Windows PowerShell
   Copy-Item -Recurse claude-article-read\start-my-day $env:USERPROFILE\.claude\skills\
   Copy-Item -Recurse claude-article-read\paper-hunt $env:USERPROFILE\.claude\skills\
   Copy-Item -Recurse claude-article-read\paper-analyze $env:USERPROFILE\.claude\skills\
   Copy-Item -Recurse claude-article-read\extract-paper-images $env:USERPROFILE\.claude\skills\
   Copy-Item -Recurse claude-article-read\paper-search $env:USERPROFILE\.claude\skills\

   # macOS/Linux
   cp -r claude-article-read/start-my-day ~/.claude/skills/
   cp -r claude-article-read/paper-hunt ~/.claude/skills/
   cp -r claude-article-read/paper-analyze ~/.claude/skills/
   cp -r claude-article-read/extract-paper-images ~/.claude/skills/
   cp -r claude-article-read/paper-search ~/.claude/skills/
   ```

2. Configure environment variables and paths (see "Configuration" section below)

3. Restart Claude Code CLI

## Configuration

> **Strongly recommended**: Read [QUICKSTART.md](QUICKSTART.md) for quick setup.

### Step 1: Set Environment Variables (Recommended)

All scripts read Obsidian Vault path through `OBSIDIAN_VAULT_PATH` environment variable, this is the simplest configuration method:

```bash
# Windows PowerShell (temporary)
$env:OBSIDIAN_VAULT_PATH = "C:/Users/YourName/Documents/Obsidian Vault"

# Windows PowerShell (permanent)
[System.Environment]::SetEnvironmentVariable("OBSIDIAN_VAULT_PATH", "C:/Users/YourName/Documents/Obsidian Vault", "User")

# macOS/Linux (add to ~/.bashrc or ~/.zshrc)
export OBSIDIAN_VAULT_PATH="/Users/yourname/Documents/Obsidian Vault"
```

After setting the environment variable, **no need to modify any paths in scripts**.

### Step 2: Create Configuration File

Copy `config.example.yaml` and modify:

```bash
cp config.example.yaml config.yaml
```

Edit `config.yaml`, modify keywords according to your research interests:

```yaml
vault_path: "/path/to/your/obsidian/vault"

research_domains:
  "Your Research Domain 1":
    keywords:
      - "keyword1"
      - "keyword2"
    arxiv_categories:
      - "cs.AI"
      - "cs.LG"
```

Then copy the modified `config.yaml` to Vault:
```bash
cp config.yaml "$OBSIDIAN_VAULT_PATH/99_System/Config/research_interests.yaml"
```

### Step 3 (Optional): Override Path via CLI Parameters

If you don't want to set environment variables, you can also specify paths through parameters when calling scripts:

```bash
python scripts/search_arxiv.py --config "/your/path/research_interests.yaml"
python scripts/scan_existing_notes.py --vault "/your/obsidian/vault"
python scripts/generate_note.py --vault "/your/obsidian/vault" --paper-id "2402.12345" --title "Paper Title" --authors "Author" --domain "Domain"
python scripts/update_graph.py --vault "/your/obsidian/vault" --paper-id "2402.12345" --title "Paper Title" --domain "Domain"
```

### Path Format Notes

- **Windows**: Can use forward slash `/` or double backslash `\\`
  - Correct: `C:/Users/Name/Documents/Vault`
  - Correct: `C:\\Users\\Name\\Documents\\Vault`
  - Wrong: `C:\Users\Name\Documents\Vault` (single backslash needs escaping in Python strings)

- **macOS/Linux**: Use forward slash `/`
  - Correct: `/Users/name/Documents/Vault`

### Obsidian Directory Structure Requirements

Your Obsidian Vault needs to contain the following directory structure:

```
YourVault/
├── 10_Daily/                    # Daily recommendation notes (auto-created)
│   └── YYYY-MM-DD-HH-mm-paper-recommendation.md  # Includes time, supports multiple searches per day
├── 20_Research/
│   └── Papers/                  # Paper detailed notes directory
│       ├── Domain1/
│       │   └── Paper-Title.md
│       │       └── images/      # Paper images
│       ├── Domain2/
│       └── Domain3/
└── 99_System/
    └── Config/
        └── research_interests.yaml  # Research interests config (copy config.yaml here)
```

## Usage

### Start Daily Paper Recommendation

Open terminal in your Obsidian Vault directory and enter:

```bash
start my day
```

This will:
1. Search high-quality papers from the last month and past year
2. Filter and score based on your research interests
3. Generate daily recommendation note (saved to `10_Daily/` directory)
4. Auto-generate detailed analysis for top 3 papers
5. Extract paper images and insert into notes
6. Auto-link keywords to existing notes

### On-Demand Targeted Paper Search (paper-hunt)

If you want to search papers in a specific direction:

```bash
paper-hunt Find 15 recent papers about LLM inference optimization
# or
paper-hunt Search 20 papers about multimodal large models
# or
paper-hunt Find 10 papers about reinforcement learning from the past year
```

This will:
1. AI intelligently parses your search intent (keywords, categories, quantity, time range)
2. Display parsed results for your confirmation
3. Execute search and generate report
4. Auto deep analysis for top 3 papers
5. Auto-link keywords to existing notes

### Analyze Single Paper

If you want to read a paper in depth:

```bash
paper-analyze 2602.12345
# or use paper title
paper-analyze "Paper Title"
```

This will:
1. Download paper PDF
2. Extract images
3. Generate detailed analysis notes
4. Update knowledge graph

### Extract Paper Images

```bash
extract-paper-images 2602.12345
```

### Search Existing Papers

```bash
paper-search "keyword"
```

## Directory Structure

```
claude-article-read/
├── README.md                 # This file
├── README_CN.md              # Chinese documentation
├── QUICKSTART.md             # Quick start guide (Chinese)
├── QUICKSTART_EN.md          # Quick start guide (English)
├── LICENSE                   # License (PolyForm Noncommercial 1.0.0)
├── config.example.yaml       # Configuration template (copy and modify)
├── requirements.txt          # Python dependencies
├── start-my-day/             # Daily recommendation skill
│   ├── skill.md              # Skill definition file
│   └── scripts/
│       ├── search_arxiv.py   # arXiv/Semantic Scholar search script
│       ├── scan_existing_notes.py  # Scan existing notes
│       └── link_keywords.py  # Keyword auto-link script
├── paper-hunt/               # On-demand targeted search skill
│   ├── skill.md              # Skill definition file
│   └── scripts/
│       ├── arxiv_categories.json      # arXiv categories complete data
│       ├── arxiv_categories_simple.txt # arXiv categories simplified
│       └── lookup_category.py         # Category lookup script
├── paper-analyze/            # Paper analysis skill
│   ├── skill.md
│   └── scripts/
│       ├── generate_note.py  # Generate note template
│       └── update_graph.py   # Update knowledge graph
├── extract-paper-images/     # Image extraction skill
│   ├── skill.md
│   └── scripts/
│       └── extract_images.py # Image extraction script
└── paper-search/             # Paper search skill
    └── skill.md
```

## Scoring Mechanism

Paper recommendation scoring is based on four dimensions:

| Dimension | Weight | Description |
|-----------|--------|-------------|
| Relevance | 40% | Match degree with research interests |
| Recency | 20% | Paper publication time |
| Popularity | 30% | Citation count/impact |
| Quality | 10% | Method quality inferred from abstract |

**Scoring Rules**:
- **Relevance**: Title keyword match (+0.5/each), abstract keyword match (+0.3/each), category match (+1.0)
- **Recency**: Within 30 days (+3), 30-90 days (+2), 90-180 days (+1), 180+ days (0)
- **Popularity**: High-impact citations > 100 (+3), 50-100 (+2), < 50 (+1)
- **Quality**: Multi-dimensional indicators (strong innovation words > weak innovation words > method indicators > quantitative results > experimental indicators)

## Common arXiv Categories

| Category Code | Name | Description |
|---------------|------|-------------|
| cs.AI | Artificial Intelligence | AI |
| cs.LG | Learning | Machine Learning |
| cs.CL | Computation and Language | NLP |
| cs.CV | Computer Vision | Computer Vision |
| cs.MM | Multimedia | Multimedia |
| cs.MA | Multiagent Systems | Multi-agent Systems |
| cs.RO | Robotics | Robotics |

## FAQ

### Q: No search results?
A: Check the following:
1. Confirm network connection is normal
2. Check if keywords in configuration file are correct
3. Try expanding arXiv category search range

### Q: Image extraction failed?
A:
1. Ensure PyMuPDF is installed: `pip install PyMuPDF`
2. Check if arXiv ID format is correct (e.g., 2602.12345)

### Q: Keyword auto-linking not accurate?
A: You can modify `COMMON_WORDS` set in `start-my-day/scripts/link_keywords.py`, add words you don't want auto-linked

### Q: "Papers directory not found" error?
A:
1. Check if `OBSIDIAN_VAULT_PATH` environment variable is correctly set
2. Confirm Obsidian Vault directory structure is correctly created (20_Research/Papers/)

### Q: "Vault path not specified" error?
A: Set `OBSIDIAN_VAULT_PATH` environment variable, or specify path via `--vault` / `--config` parameter when calling scripts.

## Advanced Configuration

### Modify Search arXiv Categories

Specify via `--categories` parameter when calling `search_arxiv.py`:

```bash
python scripts/search_arxiv.py --categories "cs.AI,cs.LG,cs.CL,cs.CV"
```

### Modify Daily Recommendation Paper Count

Specify via `--top-n` parameter when calling `search_arxiv.py`:

```bash
python scripts/search_arxiv.py --top-n 15
```

### Modify Scoring Weights

Adjust weights in `calculate_recommendation_score` function in `start-my-day/scripts/search_arxiv.py`.

## How It Works

```
User inputs "start my day"
         ↓
    1. Load research config
    2. Scan existing notes to build index
         ↓
    3. Search arXiv (last 30 days)
    4. Search Semantic Scholar (high popularity from past year)
         ↓
    5. Merge results and deduplicate
    6. Comprehensive scoring and sorting
    7. Take top N papers
         ↓
    8. Generate daily recommendation note
    9. Generate detailed analysis for top 3
    10. Auto-link keywords
```

## Contributing

Issues and Pull Requests are welcome!

## License

This project is licensed under the [PolyForm Noncommercial License 1.0.0](LICENSE).

- ✅ Allowed: Personal use, learning, research, educational institutions, charitable organizations
- ❌ Prohibited: Any form of commercial use

See [LICENSE](LICENSE) file or visit https://polyformproject.org/licenses/noncommercial/1.0.0/

## Acknowledgments

- [arXiv](https://arxiv.org/) - Open access academic paper preprint platform
- [Semantic Scholar](https://www.semanticscholar.org/) - AI-powered academic research platform
- [Claude Code](https://claude.ai/claude-code) - AI-assisted code and writing tool
- [Obsidian](https://obsidian.md/) - Powerful knowledge management tool
