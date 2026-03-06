#!/bin/bash

# claude-article-read 自动安装脚本
# 支持 macOS 和 Linux

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 打印函数
print_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
print_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# 获取脚本所在目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo ""
echo "========================================"
echo "  claude-article-read 自动安装脚本"
echo "========================================"
echo ""

# 1. 检测操作系统
print_info "检测操作系统..."
OS="$(uname -s)"
case "$OS" in
    Darwin*)  
        print_success "检测到 macOS"
        ;;
    Linux*)    
        print_success "检测到 Linux"
        ;;
    CYGWIN*|MINGW*|MSYS*)
        print_error "请使用 install.ps1 (Windows PowerShell) 脚本"
        exit 1
        ;;
    *)
        print_error "未知操作系统: $OS"
        exit 1
        ;;
esac

# 2. 检测 Python
print_info "检测 Python 环境..."
if command -v python3 &> /dev/null; then
    PYTHON_CMD="python3"
    PIP_CMD="pip3"
elif command -v python &> /dev/null; then
    PYTHON_CMD="python"
    PIP_CMD="pip"
else
    print_error "未找到 Python，请先安装 Python 3.8+"
    exit 1
fi

PYTHON_VERSION=$($PYTHON_CMD --version 2>&1 | awk '{print $2}')
print_success "检测到 Python $PYTHON_VERSION"

# 检查 Python 版本
PYTHON_MAJOR=$($PYTHON_CMD -c 'import sys; print(sys.version_info.major)')
PYTHON_MINOR=$($PYTHON_CMD -c 'import sys; print(sys.version_info.minor)')
if [ "$PYTHON_MAJOR" -lt 3 ] || ([ "$PYTHON_MAJOR" -eq 3 ] && [ "$PYTHON_MINOR" -lt 8 ]); then
    print_error "Python 版本过低，需要 3.8+，当前版本: $PYTHON_VERSION"
    exit 1
fi

# 3. 安装依赖
print_info "安装 Python 依赖..."

# 检测是否需要 --break-system-packages
NEED_BREAK_PACKAGES=false
if $PIP_CMD install --dry-run PyYAML 2>&1 | grep -q "externally-managed-environment"; then
    NEED_BREAK_PACKAGES=true
    print_warning "检测到 PEP 668 限制，将使用 --break-system-packages 标志"
fi

if [ "$NEED_BREAK_PACKAGES" = true ]; then
    $PIP_CMD install --break-system-packages -r "$SCRIPT_DIR/requirements.txt"
else
    $PIP_CMD install -r "$SCRIPT_DIR/requirements.txt"
fi
print_success "Python 依赖安装完成"

# 4. 设置环境变量
print_info "设置环境变量..."
echo ""
print_warning "请输入你的 Obsidian Vault 路径（例如：/Users/yourname/Documents/Obsidian Vault）"
read -p "Obsidian Vault 路径: " VAULT_PATH

if [ -z "$VAULT_PATH" ]; then
    print_warning "未输入路径，跳过环境变量设置。你可以稍后手动设置。"
else
    # 验证路径
    if [ ! -d "$VAULT_PATH" ]; then
        print_warning "路径不存在: $VAULT_PATH"
        read -p "是否创建此目录？(y/n): " CREATE_DIR
        if [ "$CREATE_DIR" = "y" ] || [ "$CREATE_DIR" = "Y" ]; then
            mkdir -p "$VAULT_PATH"
            print_success "目录已创建: $VAULT_PATH"
        fi
    fi
    
    # 添加到 shell 配置文件
    SHELL_RC=""
    if [ -n "$ZSH_VERSION" ]; then
        SHELL_RC="$HOME/.zshrc"
    elif [ -n "$BASH_VERSION" ]; then
        SHELL_RC="$HOME/.bashrc"
    fi
    
    if [ -n "$SHELL_RC" ]; then
        # 检查是否已存在
        if ! grep -q "OBSIDIAN_VAULT_PATH" "$SHELL_RC" 2>/dev/null; then
            echo "" >> "$SHELL_RC"
            echo "# claude-article-read" >> "$SHELL_RC"
            echo "export OBSIDIAN_VAULT_PATH=\"$VAULT_PATH\"" >> "$SHELL_RC"
            print_success "环境变量已添加到 $SHELL_RC"
            export OBSIDIAN_VAULT_PATH="$VAULT_PATH"
        else
            print_warning "OBSIDIAN_VAULT_PATH 已存在于 $SHELL_RC，请手动更新"
        fi
    fi
fi

# 5. 创建 Obsidian 目录结构
if [ -n "$OBSIDIAN_VAULT_PATH" ] && [ -d "$OBSIDIAN_VAULT_PATH" ]; then
    print_info "创建 Obsidian 目录结构..."
    mkdir -p "$OBSIDIAN_VAULT_PATH/10_Daily"
    mkdir -p "$OBSIDIAN_VAULT_PATH/20_Research/Papers"
    mkdir -p "$OBSIDIAN_VAULT_PATH/99_System/Config"
    print_success "Obsidian 目录结构已创建"
    
    # 复制配置文件
    if [ -f "$SCRIPT_DIR/config.example.yaml" ]; then
        cp "$SCRIPT_DIR/config.example.yaml" "$OBSIDIAN_VAULT_PATH/99_System/Config/research_interests.yaml"
        print_success "配置文件已复制到 Vault"
    fi
fi

# 6. 安装技能到 Claude Code
print_info "安装技能到 Claude Code..."
CLAUDE_SKILLS_DIR="$HOME/.claude/skills"
mkdir -p "$CLAUDE_SKILLS_DIR"

SKILLS=("start-my-day" "paper-analyze" "extract-paper-images" "paper-search" "paper-hunt")

for SKILL in "${SKILLS[@]}"; do
    if [ -d "$SCRIPT_DIR/$SKILL" ]; then
        cp -r "$SCRIPT_DIR/$SKILL" "$CLAUDE_SKILLS_DIR/"
        print_success "已安装技能: $SKILL"
    fi
done

# 7. 完成
echo ""
echo "========================================"
print_success "安装完成！"
echo "========================================"
echo ""
echo "后续步骤："
echo ""
if [ -z "$OBSIDIAN_VAULT_PATH" ]; then
    echo "1. 设置环境变量："
    echo "   export OBSIDIAN_VAULT_PATH=\"/path/to/your/vault\""
    echo ""
fi
echo "2. 编辑配置文件（根据你的研究兴趣修改关键词）："
if [ -n "$OBSIDIAN_VAULT_PATH" ]; then
    echo "   $OBSIDIAN_VAULT_PATH/99_System/Config/research_interests.yaml"
else
    echo "   <your-vault>/99_System/Config/research_interests.yaml"
fi
echo ""
echo "3. 重启终端或运行："
if [ -n "$SHELL_RC" ]; then
    echo "   source $SHELL_RC"
fi
echo ""
echo "4. 在 Claude Code 中使用："
echo "   start my day"
echo ""
echo "项目地址: https://github.com/wangzr040220/claude-article-read"
echo ""
