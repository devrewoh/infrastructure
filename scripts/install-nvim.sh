#!/bin/sh
# Install Neovim and Go development tools
# Part of infrastructure setup

set -e
set -u

echo "=== Neovim Development Environment Setup ==="

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

# Install Neovim
install_neovim() {
    if command -v nvim >/dev/null 2>&1; then
        echo "Neovim is already installed: $(nvim --version | head -n1)"
        return 0
    fi

    PKG_MGR=$(detect_package_manager)

    case "$PKG_MGR" in
        "apt")
            echo "Installing Neovim via apt..."
            sudo apt update
            sudo apt install -y neovim
            ;;
        "pacman")
            echo "Installing Neovim via pacman..."
            sudo pacman -S --noconfirm neovim
            ;;
        "dnf")
            echo "Installing Neovim via dnf..."
            sudo dnf install -y neovim
            ;;
        "brew")
            echo "Installing Neovim via brew..."
            brew install neovim
            ;;
        *)
            echo "Error: Unsupported package manager. Please install Neovim manually."
            exit 1
            ;;
    esac
}

# Install Go development tools
install_go_tools() {
    if ! command -v go >/dev/null 2>&1; then
        echo "Warning: Go is not installed. Please install Go first."
        echo "Skipping Go tools installation."
        return 0
    fi

    echo "Installing Go development tools..."
    
    # Install gopls (Go Language Server)
    if ! command -v gopls >/dev/null 2>&1; then
        echo "Installing gopls..."
        go install golang.org/x/tools/gopls@latest
    else
        echo "gopls is already installed: $(gopls version)"
    fi

    # Verify Go tools installation
    if command -v gopls >/dev/null 2>&1; then
        echo "Go tools installation successful"
    else
        echo "Warning: Go tools may not be in PATH. Check your Go installation."
    fi
}

# Main installation
main() {
    install_neovim
    install_go_tools

    # Verify installations
    if command -v nvim >/dev/null 2>&1; then
        echo "Setup complete: $(nvim --version | head -n1)"
    else
        echo "Error: Neovim installation failed"
        exit 1
    fi

    echo ""
    echo "Next steps:"
    echo "1. Set up your dotfiles: https://github.com/yourusername/dotfiles"
    echo "2. Create Neovim configuration in ~/.config/nvim/init.vim"
}

main
