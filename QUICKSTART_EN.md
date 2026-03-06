# Quick Start Guide

[中文版](QUICKSTART.md)

This is a quick setup guide for using claude-article-read.

## Step 1: Install Dependencies

Run in terminal:

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

## Step 2: Configuration

### 2.1 Set Environment Variables

Set the `OBSIDIAN_VAULT_PATH` environment variable to point to your Obsidian Vault path. All scripts will automatically read this variable, no need to manually modify paths in scripts.

```bash
# Windows PowerShell (permanent, restart terminal after setting)
[System.Environment]::SetEnvironmentVariable("OBSIDIAN_VAULT_PATH", "C:/Users/YourName/Documents/Obsidian Vault", "User")

# macOS/Linux (add to ~/.bashrc or ~/.zshrc)
echo 'export OBSIDIAN_VAULT_PATH="/Users/yourname/Documents/Obsidian Vault"' >> ~/.bashrc
source ~/.bashrc
```

### 2.2 Create Configuration File

```bash
cd claude-article-read
cp config.example.yaml config.yaml
```

Edit `config.yaml`, modify:

```yaml
# Change this path to your Obsidian Vault path
vault_path: "/path/to/your/obsidian/vault"

# Modify keywords according to your research interests
research_domains:
  "Your Research Domain 1":
    keywords:
      - "keyword1"
      - "keyword2"
```

### 2.3 Put Configuration File into Vault

```bash
# macOS/Linux
cp config.yaml "$OBSIDIAN_VAULT_PATH/99_System/Config/research_interests.yaml"

# Windows PowerShell
Copy-Item config.yaml "$env:OBSIDIAN_VAULT_PATH\99_System\Config\research_interests.yaml"
```

### 2.4 Install Skills to Claude Code

Copy the five skill folders from claude-article-read directory to your Claude Code skills directory:

```bash
# macOS/Linux
cp -r claude-article-read/start-my-day ~/.claude/skills/
cp -r claude-article-read/paper-hunt ~/.claude/skills/
cp -r claude-article-read/paper-analyze ~/.claude/skills/
cp -r claude-article-read/extract-paper-images ~/.claude/skills/
cp -r claude-article-read/paper-search ~/.claude/skills/

# Windows PowerShell
Copy-Item -Recurse claude-article-read\start-my-day $env:USERPROFILE\.claude\skills\
Copy-Item -Recurse claude-article-read\paper-hunt $env:USERPROFILE\.claude\skills\
Copy-Item -Recurse claude-article-read\paper-analyze $env:USERPROFILE\.claude\skills\
Copy-Item -Recurse claude-article-read\extract-paper-images $env:USERPROFILE\.claude\skills\
Copy-Item -Recurse claude-article-read\paper-search $env:USERPROFILE\.claude\skills\
```

## Step 3: Create Obsidian Directory Structure

Create the following directories in your Obsidian Vault:

```
YourVault/
├── 10_Daily/
├── 20_Research/
│   └── Papers/
├── 99_System/
│   └── Config/
│       └── research_interests.yaml  # Copied in step 2
```

## Getting Started

### 1. Open Claude Code

Open terminal in your Obsidian Vault directory:

```bash
# Switch to your Obsidian Vault directory
cd "$OBSIDIAN_VAULT_PATH"

# Start Claude Code
claude-code
```

### 2. Start Daily Paper Recommendation

Enter in Claude Code:

```
start my day
```

### 3. On-Demand Targeted Paper Search

If you want to search papers in a specific direction:

```
paper-hunt Find 15 recent papers about LLM inference optimization
```

### 4. Analyze Single Paper

Enter in Claude Code:

```
paper-analyze 2602.12345
```

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

## Troubleshooting

### Issue: "Vault path not specified" or "Papers directory not found"

**Solution**:
1. Confirm environment variable is set:
   ```bash
   # Windows PowerShell
   echo $env:OBSIDIAN_VAULT_PATH

   # macOS/Linux
   echo $OBSIDIAN_VAULT_PATH
   ```
2. If empty, go back to step 2 to set environment variable
3. Confirm directory structure is correctly created

### Issue: Paper image extraction failed

**Solution**:
1. Confirm PyMuPDF is installed: `pip install PyMuPDF`
2. Check if arXiv ID format is correct (e.g., 2602.12345)

### Issue: Keyword auto-linking not accurate

**Solution**: Edit `COMMON_WORDS` set in `start-my-day/scripts/link_keywords.py`, add words you don't want auto-linked.

## Need Help?

- Check [README.md](README.md) for detailed instructions
- Submit Issue to GitHub repository
