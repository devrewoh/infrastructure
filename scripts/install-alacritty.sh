#!/bin/sh
# Install Alacritty terminal emulator
# Part of infrastructure setup

set -e
set -u

echo "=== Alacritty Installation ==="

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

# Check if alacritty is already installed
if command -v alacritty >/dev/null 2>&1; then
    echo "Alacritty is already installed: $(alacritty --version)"
    exit 0
fi

# Detect and install
PKG_MGR=$(detect_package_manager)

case "$PKG_MGR" in
    "apt")
        echo "Installing Alacritty via apt..."
        sudo apt update
        sudo apt install -y alacritty
        ;;
    "pacman")
        echo "Installing Alacritty via pacman..."
        sudo pacman -S --noconfirm alacritty
        ;;
    "dnf")
        echo "Installing Alacritty via dnf..."
        sudo dnf install -y alacritty
        ;;
    "brew")
        echo "Installing Alacritty via brew..."
        brew install --cask alacritty
        ;;
    *)
        echo "Error: Unsupported package manager. Please install Alacritty manually."
        exit 1
        ;;
esac

# Verify installation
if command -v alacritty >/dev/null 2>&1; then
    echo "Alacritty installation successful: $(alacritty --version)"
    echo ""
    echo "Next steps:"
    echo "1. Set up your dotfiles: https://github.com/yourusername/dotfiles"
    echo "2. Create Alacritty configuration in ~/.config/alacritty/alacritty.yml"
else
    echo "Error: Alacritty installation failed"
    exit 1
fi
