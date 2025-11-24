#!/bin/bash

# Flutter SDK 安装脚本
# 支持 Linux 和 macOS

set -e

echo "🚀 Flutter SDK 安装脚本"
echo "======================="
echo ""

# 检测操作系统
OS=$(uname -s)
ARCH=$(uname -m)

if [ "$OS" = "Linux" ]; then
    echo "检测到系统: Linux ($ARCH)"
    if [ "$ARCH" = "x86_64" ]; then
        FLUTTER_URL="https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.16.0-stable.tar.xz"
    else
        echo "❌ 不支持的架构: $ARCH"
        exit 1
    fi
elif [ "$OS" = "Darwin" ]; then
    echo "检测到系统: macOS ($ARCH)"
    if [ "$ARCH" = "arm64" ]; then
        FLUTTER_URL="https://storage.googleapis.com/flutter_infra_release/releases/stable/macos/flutter_macos_arm64_3.16.0-stable.zip"
    else
        FLUTTER_URL="https://storage.googleapis.com/flutter_infra_release/releases/stable/macos/flutter_macos_3.16.0-stable.zip"
    fi
else
    echo "❌ 不支持的操作系统: $OS"
    exit 1
fi

INSTALL_DIR="$HOME/development"
FLUTTER_DIR="$INSTALL_DIR/flutter"

echo ""
echo "📥 下载 Flutter SDK..."
echo "   URL: $FLUTTER_URL"
echo "   安装目录: $FLUTTER_DIR"
echo ""

# 创建安装目录
mkdir -p "$INSTALL_DIR"
cd "$INSTALL_DIR"

# 下载 Flutter
if [ "$OS" = "Linux" ]; then
    echo "正在下载..."
    curl -L "$FLUTTER_URL" -o flutter.tar.xz
    echo "正在解压..."
    tar xf flutter.tar.xz
    rm flutter.tar.xz
else
    echo "正在下载..."
    curl -L "$FLUTTER_URL" -o flutter.zip
    echo "正在解压..."
    unzip -q flutter.zip
    rm flutter.zip
fi

echo ""
echo "✅ Flutter SDK 下载完成"
echo ""

# 配置环境变量
SHELL_RC=""
if [ -f "$HOME/.bashrc" ]; then
    SHELL_RC="$HOME/.bashrc"
elif [ -f "$HOME/.zshrc" ]; then
    SHELL_RC="$HOME/.zshrc"
fi

if [ -n "$SHELL_RC" ]; then
    echo "📝 配置环境变量到 $SHELL_RC..."

    # 检查是否已存在Flutter配置
    if ! grep -q "flutter/bin" "$SHELL_RC"; then
        echo "" >> "$SHELL_RC"
        echo "# Flutter SDK" >> "$SHELL_RC"
        echo "export PATH=\"\$PATH:$FLUTTER_DIR/bin\"" >> "$SHELL_RC"
        echo "✅ 环境变量已添加"
    else
        echo "⚠️  环境变量已存在，跳过"
    fi
fi

# 临时添加到当前会话
export PATH="$PATH:$FLUTTER_DIR/bin"

echo ""
echo "🔧 运行 Flutter doctor..."
flutter doctor

echo ""
echo "================================"
echo "✅ Flutter 安装完成!"
echo ""
echo "📝 下一步操作:"
echo "   1. 重新加载Shell配置:"
echo "      source $SHELL_RC"
echo ""
echo "   2. 或重新打开终端窗口"
echo ""
echo "   3. 验证安装:"
echo "      flutter --version"
echo ""
echo "   4. 完成v1.0开发:"
echo "      cd lib"
echo "      flutter packages pub run build_runner build"
echo ""
