# claude-article-read 自动安装脚本 (Windows PowerShell)
# 需要以管理员权限运行

param(
    [string]$VaultPath = ""
)

# 颜色函数
function Write-Info { param($msg) Write-Host "[INFO] " -ForegroundColor Blue -NoNewline; Write-Host $msg }
function Write-Success { param($msg) Write-Host "[SUCCESS] " -ForegroundColor Green -NoNewline; Write-Host $msg }
function Write-Warning { param($msg) Write-Host "[WARNING] " -ForegroundColor Yellow -NoNewline; Write-Host $msg }
function Write-Error { param($msg) Write-Host "[ERROR] " -ForegroundColor Red -NoNewline; Write-Host $msg }

# 获取脚本所在目录
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

Write-Host ""
Write-Host "========================================"
Write-Host "  claude-article-read 自动安装脚本"
Write-Host "========================================"
Write-Host ""

# 1. 检测操作系统
Write-Info "检测操作系统..."
$OS = [System.Environment]::OSVersion.Platform
$IsWindows = $true  # PowerShell 脚本只在 Windows 上运行
Write-Success "检测到 Windows"

# 2. 检测 Python
Write-Info "检测 Python 环境..."
$PythonCmd = $null
$PipCmd = $null

if (Get-Command python3 -ErrorAction SilentlyContinue) {
    $PythonCmd = "python3"
    $PipCmd = "pip3"
} elseif (Get-Command python -ErrorAction SilentlyContinue) {
    $PythonCmd = "python"
    $PipCmd = "pip"
} else {
    Write-Error "未找到 Python，请先安装 Python 3.8+"
    Write-Info "可以从 https://www.python.org/downloads/ 下载 Python"
    exit 1
}

$PythonVersion = & $PythonCmd --version 2>&1
Write-Success "检测到 $PythonVersion"

# 检查 Python 版本
$VersionMatch = $PythonVersion -match "(\d+)\.(\d+)"
if ($VersionMatch) {
    $Major = [int]$matches[1]
    $Minor = [int]$matches[2]
    if ($Major -lt 3 -or ($Major -eq 3 -and $Minor -lt 8)) {
        Write-Error "Python 版本过低，需要 3.8+，当前版本: $PythonVersion"
        exit 1
    }
}

# 3. 安装依赖
Write-Info "安装 Python 依赖..."
$RequirementsPath = Join-Path $ScriptDir "requirements.txt"

try {
    & $PipCmd install -r $RequirementsPath
    Write-Success "Python 依赖安装完成"
} catch {
    Write-Warning "普通安装失败，尝试使用 --user 标志..."
    try {
        & $PipCmd install --user -r $RequirementsPath
        Write-Success "Python 依赖安装完成（用户模式）"
    } catch {
        Write-Error "依赖安装失败: $_"
        exit 1
    }
}

# 4. 设置环境变量
Write-Info "设置环境变量..."

if ([string]::IsNullOrEmpty($VaultPath)) {
    Write-Warning "请输入你的 Obsidian Vault 路径"
    Write-Info "例如: C:\Users\YourName\Documents\Obsidian Vault"
    $VaultPath = Read-Host "Obsidian Vault 路径"
}

if ([string]::IsNullOrEmpty($VaultPath)) {
    Write-Warning "未输入路径，跳过环境变量设置。你可以稍后手动设置。"
} else {
    # 验证路径
    if (-not (Test-Path $VaultPath)) {
        Write-Warning "路径不存在: $VaultPath"
        $CreateDir = Read-Host "是否创建此目录？(y/n)"
        if ($CreateDir -eq "y" -or $CreateDir -eq "Y") {
            New-Item -ItemType Directory -Path $VaultPath -Force | Out-Null
            Write-Success "目录已创建: $VaultPath"
        }
    }
    
    # 设置用户环境变量
    [System.Environment]::SetEnvironmentVariable("OBSIDIAN_VAULT_PATH", $VaultPath, "User")
    Write-Success "环境变量 OBSIDIAN_VAULT_PATH 已设置"
    
    # 当前会话也设置
    $env:OBSIDIAN_VAULT_PATH = $VaultPath
}

# 5. 创建 Obsidian 目录结构
if (-not [string]::IsNullOrEmpty($env:OBSIDIAN_VAULT_PATH) -and (Test-Path $env:OBSIDIAN_VAULT_PATH)) {
    Write-Info "创建 Obsidian 目录结构..."
    
    $Directories = @(
        "10_Daily",
        "20_Research\Papers",
        "99_System\Config"
    )
    
    foreach ($Dir in $Directories) {
        $FullPath = Join-Path $env:OBSIDIAN_VAULT_PATH $Dir
        if (-not (Test-Path $FullPath)) {
            New-Item -ItemType Directory -Path $FullPath -Force | Out-Null
        }
    }
    Write-Success "Obsidian 目录结构已创建"
    
    # 复制配置文件
    $ConfigSource = Join-Path $ScriptDir "config.example.yaml"
    $ConfigDest = Join-Path $env:OBSIDIAN_VAULT_PATH "99_System\Config\research_interests.yaml"
    if (Test-Path $ConfigSource) {
        Copy-Item $ConfigSource $ConfigDest -Force
        Write-Success "配置文件已复制到 Vault"
    }
}

# 6. 安装技能到 Claude Code
Write-Info "安装技能到 Claude Code..."
$ClaudeSkillsDir = Join-Path $env:USERPROFILE ".claude\skills"
if (-not (Test-Path $ClaudeSkillsDir)) {
    New-Item -ItemType Directory -Path $ClaudeSkillsDir -Force | Out-Null
}

$Skills = @("start-my-day", "paper-analyze", "extract-paper-images", "paper-search", "paper-hunt")

foreach ($Skill in $Skills) {
    $SkillPath = Join-Path $ScriptDir $Skill
    if (Test-Path $SkillPath) {
        $DestPath = Join-Path $ClaudeSkillsDir $Skill
        if (Test-Path $DestPath) {
            Remove-Item $DestPath -Recurse -Force
        }
        Copy-Item $SkillPath $DestPath -Recurse -Force
        Write-Success "已安装技能: $Skill"
    }
}

# 7. 完成
Write-Host ""
Write-Host "========================================"
Write-Success "安装完成！"
Write-Host "========================================"
Write-Host ""
Write-Host "后续步骤："
Write-Host ""
if ([string]::IsNullOrEmpty($env:OBSIDIAN_VAULT_PATH)) {
    Write-Host "1. 设置环境变量："
    Write-Host "   `$env:OBSIDIAN_VAULT_PATH = 'C:\path\to\your\vault'"
    Write-Host "   或永久设置："
    Write-Host "   [System.Environment]::SetEnvironmentVariable('OBSIDIAN_VAULT_PATH', 'C:\path\to\your\vault', 'User')"
    Write-Host ""
}
Write-Host "2. 编辑配置文件（根据你的研究兴趣修改关键词）："
if (-not [string]::IsNullOrEmpty($env:OBSIDIAN_VAULT_PATH)) {
    Write-Host "   $env:OBSIDIAN_VAULT_PATH\99_System\Config\research_interests.yaml"
} else {
    Write-Host "   <your-vault>\99_System\Config\research_interests.yaml"
}
Write-Host ""
Write-Host "3. 重启 PowerShell 或终端"
Write-Host ""
Write-Host "4. 在 Claude Code 中使用："
Write-Host "   start my day"
Write-Host ""
Write-Host "项目地址: https://github.com/wangzr040220/claude-article-read"
Write-Host ""
