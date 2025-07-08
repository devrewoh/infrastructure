#!/bin/sh
# Install tmux terminal multiplexer
# Part of infrastructure setup

set -e
set -u

echo "=== tmux Installation ==="

# Detect package manager
detect_package_manager() {
    if command -v apt >/dev/null 2>&1; then
        echo "apt"
    elif command -v pacman >/dev/null 2>&1; then
        echo "pacman"
    elif command -v dnf >/dev/null 2>&1; then
        echo "dnf"
    elif command -v brew >/dev/null 2>&1; then
        echo "brew"
    else
        echo "unknown"
    fi
}

# Check if tmux is already installed
if command -v tmux >/dev/null 2>&1; then
    echo "tmux is already installed: $(tmux -V)"
    exit 0
fi

# Detect and install
PKG_MGR=$(detect_package_manager)

case "$PKG_MGR" in
    "apt")
        echo "Installing tmux via apt..."
        sudo apt update
        sudo apt install -y tmux
        ;;
    "pacman")
        echo "Installing tmux via pacman..."
        sudo pacman -S --noconfirm tmux
        ;;
    "dnf")
        echo "Installing tmux via dnf..."
        sudo dnf install -y tmux
        ;;
    "brew")
        echo "Installing tmux via brew..."
        brew install tmux
        ;;
    *)
        echo "Error: Unsupported package manager. Please install tmux manually."
        exit 1
        ;;
esac

# Verify installation
if command -v tmux >/dev/null 2>&1; then
    echo "tmux installation successful: $(tmux -V)"
    echo ""
    echo "Next steps:"
    echo "1. Set up your dotfiles: https://github.com/yourusername/dotfiles"
    echo "2. Create tmux configuration in ~/.config/tmux/tmux.conf"
else
    echo "Error: tmux installation failed"
    exit 1
fi
