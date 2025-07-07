#!/bin/sh
# POSIX-Compliant Universal Go Installer
# Works with /bin/sh on any POSIX system (Linux, macOS, BSD, etc.)

# Exit on any error
set -e

# ================================
# Configuration
# ================================
GO_VERSION="1.24.4"
INSTALL_DIR="$HOME/.local"
GO_DIR="$INSTALL_DIR/go"

# ================================
# Utility Functions
# ================================
log() {
    printf "%s\n" "$1"
}

error() {
    printf "Error: %s\n" "$1" >&2
    exit 1
}

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# ================================
# Platform Detection
# ================================
detect_platform() {
    OS=$(uname -s)
    MACHINE=$(uname -m)
    
    case "$OS" in
        Linux*)
            PLATFORM="linux"
            ARCH="amd64"
            if grep -q Microsoft /proc/version 2>/dev/null; then
                log "🐧 Detected: Windows Subsystem for Linux (WSL)"
            else
                log "🐧 Detected: Linux"
            fi
            ;;
        Darwin*)
            PLATFORM="darwin"
            case "$MACHINE" in
                arm64)
                    ARCH="arm64"
                    log "🍎 Detected: macOS (Apple Silicon)"
                    ;;
                x86_64)
                    ARCH="amd64"
                    log "🍎 Detected: macOS (Intel)"
                    ;;
                *)
                    error "Unsupported macOS architecture: $MACHINE"
                    ;;
            esac
            ;;
        CYGWIN*|MINGW*|MSYS*)
            PLATFORM="windows"
            ARCH="amd64"
            log "🪟 Detected: Windows (Git Bash/MSYS2)"
            ;;
        *)
            error "Unsupported platform: $OS"
            ;;
    esac
    
    log "Platform: $PLATFORM-$ARCH"
}

# ================================
# Directory Validation and Creation
# ================================
validate_permissions() {
    log "🔒 Validating permissions..."
    
    # Check if we can write to home directory
    if [ ! -w "$HOME" ]; then
        error "Cannot write to home directory: $HOME"
    fi
    
    # Check if .local exists and is writable, or if we can create it
    if [ -d "$HOME/.local" ]; then
        if [ ! -w "$HOME/.local" ]; then
            error "Cannot write to existing directory: $HOME/.local"
        fi
    fi
    
    log "✅ Permissions validated"
}

create_directories() {
    log "📁 Creating directory structure..."
    
    # Create directories with explicit checks
    for dir in "$INSTALL_DIR" "$HOME/workspace" "$HOME/.config" "$HOME/.cache" "$HOME/.local/bin" "$HOME/.local/share"; do
        if [ ! -d "$dir" ]; then
            log "Creating: $dir"
            if ! mkdir -p "$dir"; then
                error "Failed to create directory: $dir"
            fi
        else
            log "Exists: $dir"
        fi
        
        # Verify we can write to it
        if [ ! -w "$dir" ]; then
            error "Cannot write to directory: $dir"
        fi
    done
    
    log "✅ Directory structure ready"
}

# ================================
# Safe Cleanup with Comprehensive Checks
# ================================
cleanup_existing() {
    log "🧹 Safely cleaning up existing Go installations..."
    
    # Check if target directory exists and what's in it
    if [ -d "$GO_DIR" ]; then
        log "Found existing Go installation at: $GO_DIR"
        
        # Verify it's actually a Go installation (safety check)
        if [ -f "$GO_DIR/bin/go" ]; then
            EXISTING_VERSION=$("$GO_DIR/bin/go" version 2>/dev/null | cut -d' ' -f3 2>/dev/null || echo "unknown")
            log "Existing Go version: $EXISTING_VERSION"
        fi
        
        # Check if any processes are using files in the directory
        if command_exists lsof; then
            if lsof "$GO_DIR" >/dev/null 2>&1; then
                log "Warning: Files in $GO_DIR are currently in use"
                log "Waiting 3 seconds for processes to finish..."
                sleep 3
            fi
        fi
        
        # Check if directory is writable
        if [ ! -w "$GO_DIR" ]; then
            error "Cannot remove existing installation - no write permission: $GO_DIR"
        fi
        
        log "Removing existing installation..."
        if ! rm -rf "$GO_DIR"; then
            error "Failed to remove existing installation: $GO_DIR"
        fi
        
        log "✅ Existing installation removed"
    else
        log "No existing Go installation found at: $GO_DIR"
    fi
    
    # Clean Go module cache if Go exists anywhere
    if command_exists go; then
        log "Cleaning Go module cache..."
        go clean -modcache 2>/dev/null || log "Note: Could not clean module cache"
    fi
    
    # Clean workspace cache safely
    if [ -d "$HOME/go" ]; then
        log "Cleaning Go workspace cache..."
        
        # Only remove cache directories, preserve src
        for cache_dir in "$HOME/go/pkg" "$HOME/go/bin"; do
            if [ -d "$cache_dir" ]; then
                log "Removing cache: $cache_dir"
                chmod -R u+w "$cache_dir" 2>/dev/null || true
                if ! rm -rf "$cache_dir"; then
                    log "Warning: Could not remove $cache_dir"
                fi
            fi
        done
        
        # Check if src directory exists and warn user
        if [ -d "$HOME/go/src" ]; then
            log "Note: Preserving your projects in $HOME/go/src"
        fi
    fi
    
    log "✅ Cleanup complete"
}

# ================================
# Safe Download with Verification
# ================================
download_go() {
    log "📦 Downloading Go $GO_VERSION for $PLATFORM-$ARCH..."
    
    # Construct filename and URL
    if [ "$PLATFORM" = "windows" ]; then
        FILENAME="go${GO_VERSION}.windows-${ARCH}.zip"
    else
        FILENAME="go${GO_VERSION}.${PLATFORM}-${ARCH}.tar.gz"
    fi
    
    DOWNLOAD_URL="https://golang.org/dl/$FILENAME"
    log "📥 Downloading: $DOWNLOAD_URL"
    
    # Ensure /tmp is writable
    if [ ! -w "/tmp" ]; then
        error "Cannot write to /tmp directory"
    fi
    
    # Change to temp directory and clean up any existing file
    cd /tmp
    if [ -f "$FILENAME" ]; then
        log "Removing existing download: $FILENAME"
        rm -f "$FILENAME"
    fi
    
    # Download using available tool
    if command_exists curl; then
        log "Using curl for download..."
        if ! curl -L "$DOWNLOAD_URL" -o "$FILENAME"; then
            error "Download failed using curl"
        fi
    elif command_exists wget; then
        log "Using wget for download..."
        if ! wget "$DOWNLOAD_URL" -O "$FILENAME"; then
            error "Download failed using wget"
        fi
    else
        error "Neither curl nor wget found. Please install one."
    fi
    
    # Verify download exists and has reasonable size
    if [ ! -f "$FILENAME" ]; then
        error "Download failed - file not found: $FILENAME"
    fi
    
    # Check file size (Go downloads should be > 50MB)
    if command_exists stat; then
        FILE_SIZE=$(stat -c%s "$FILENAME" 2>/dev/null || stat -f%z "$FILENAME" 2>/dev/null || echo "0")
        if [ "$FILE_SIZE" -lt 52428800 ]; then  # 50MB in bytes
            error "Download appears incomplete - file too small: $FILE_SIZE bytes"
        fi
        log "Downloaded file size: $FILE_SIZE bytes"
    fi
    
    log "✅ Download completed and verified"
}

# ================================
# Extract and Install Go
# ================================
install_go() {
    log "📂 Installing Go to $INSTALL_DIR..."
    
    # Extract based on file type
    if [ "$PLATFORM" = "windows" ]; then
        if command_exists unzip; then
            unzip -q "$FILENAME" -d "$INSTALL_DIR"
        else
            error "unzip command not found. Required for Windows installation."
        fi
    else
        tar -C "$INSTALL_DIR" -xzf "$FILENAME"
    fi
    
    # Cleanup download file
    rm -f "$FILENAME"
    
    # Verify installation
    if [ ! -f "$GO_DIR/bin/go" ]; then
        error "Installation failed - Go binary not found at $GO_DIR/bin/go"
    fi
    
    log "✅ Go installed successfully"
    "$GO_DIR/bin/go" version
}

# ================================
# Setup Environment Configuration
# ================================
setup_environment() {
    log "⚙️  Setting up environment configuration..."
    
    # Create .profile with POSIX-compliant syntax only
    cat > "$HOME/.profile" << 'EOF'
# ~/.profile - POSIX-compliant environment setup
# Works with any POSIX shell: sh, bash, zsh, dash, etc.

# XDG Base Directory Specification
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_DATA_HOME="$HOME/.local/share" 
export XDG_CACHE_HOME="$HOME/.cache"

# Local installation paths
export PATH="$HOME/.local/bin:$PATH"

# Go environment
if [ -d "$HOME/.local/go" ]; then
    export GOROOT="$HOME/.local/go"
    export PATH="$GOROOT/bin:$PATH"
fi
export GOPATH="$HOME/go"
export PATH="$PATH:$GOPATH/bin"

# Go configuration
export GOPROXY="https://proxy.golang.org,direct"
export GOSUMDB="sum.golang.org"

# Development environment
export EDITOR="nvim"
export VISUAL="nvim"
export WORKSPACE="$HOME/workspace"

# Locale
export LANG="en_US.UTF-8"
export LC_ALL="en_US.UTF-8"

# Platform detection
case "$(uname -s)" in
    Linux*)     export OS_TYPE="linux";;
    Darwin*)    export OS_TYPE="macos";;
    CYGWIN*|MINGW*|MSYS*) export OS_TYPE="windows";;
    *)          export OS_TYPE="unknown";;
esac
EOF

    # Source the profile in current session
    . "$HOME/.profile"
    
    log "✅ Environment configured"
}

# ================================
# Install Development Tools
# ================================
install_dev_tools() {
    log "🔧 Installing Go development tools..."
    
    # Ensure Go is available in current session
    export PATH="$GO_DIR/bin:$PATH"
    export GOPATH="$HOME/go"
    export PATH="$PATH:$GOPATH/bin"
    
    # Install tools one by one with error checking
    log "Installing gopls (Language Server)..."
    "$GO_DIR/bin/go" install golang.org/x/tools/gopls@latest
    
    log "Installing goimports (Import organizer)..."
    "$GO_DIR/bin/go" install golang.org/x/tools/cmd/goimports@latest
    
    log "Installing golangci-lint (Linter)..."
    "$GO_DIR/bin/go" install github.com/golangci/golangci-lint/cmd/golangci-lint@latest
    
    log "Installing delve (Debugger)..."
    "$GO_DIR/bin/go" install github.com/go-delve/delve/cmd/dlv@latest
    
    log "Installing air (Live reload)..."
    "$GO_DIR/bin/go" install github.com/air-verse/air@latest
    
    log "✅ Development tools installed"
}

# ================================
# Verification
# ================================
verify_installation() {
    log "🔍 Verifying installation..."
    
    # Source environment
    . "$HOME/.profile"
    
    log ""
    log "Go Installation:"
    log "================"
    go version
    log "GOROOT: $(go env GOROOT)"
    log "GOPATH: $(go env GOPATH)"
    log "Go binary: $(command -v go)"
    
    log ""
    log "Development Tools:"
    log "=================="
    
    # Check each tool individually (POSIX way, no arrays)
    if command_exists gopls; then
        log "✅ gopls: $(command -v gopls)"
    else
        log "❌ gopls: NOT FOUND"
    fi
    
    if command_exists goimports; then
        log "✅ goimports: $(command -v goimports)"
    else
        log "❌ goimports: NOT FOUND"
    fi
    
    if command_exists golangci-lint; then
        log "✅ golangci-lint: $(command -v golangci-lint)"
    else
        log "❌ golangci-lint: NOT FOUND"
    fi
    
    if command_exists dlv; then
        log "✅ dlv: $(command -v dlv)"
    else
        log "❌ dlv: NOT FOUND"
    fi
    
    if command_exists air; then
        log "✅ air: $(command -v air)"
    else
        log "❌ air: NOT FOUND"
    fi
    
    log ""
    log "Directory Structure:"
    log "==================="
    log "GOROOT: $HOME/.local/go"
    log "GOPATH: $HOME/go"
    log "Workspace: $HOME/workspace"
    log "Config: $HOME/.config"
    
    # Test basic functionality
    log ""
    log "🧪 Testing Go functionality..."
    TEST_DIR="/tmp/go-test-$$"
    mkdir -p "$TEST_DIR"
    cd "$TEST_DIR"
    
    go mod init test-install
    printf 'package main\nimport "fmt"\nfunc main() { fmt.Println("Go installation working!") }\n' > main.go
    go run main.go
    
    cd /tmp
    rm -rf "$TEST_DIR"
    
    log "✅ Installation verification complete!"
}

# ================================
# Shell Integration Instructions
# ================================
show_shell_instructions() {
    log ""
    log "🐚 Shell Integration:"
    log "===================="
    
    case "$PLATFORM" in
        linux|darwin)
            log "Add this line to your shell config file:"
            log "  ~/.bashrc or ~/.zshrc:"
            log "    . ~/.profile"
            log ""
            log "Or the environment will be loaded automatically"
            log "when you start a new login shell."
            ;;
        windows)
            log "For Git Bash on Windows:"
            log "  Add '. ~/.profile' to ~/.bashrc"
            log ""
            log "For PowerShell, manually add to PATH:"
            log "  \$env:PATH += \";$HOME\\.local\\go\\bin;$HOME\\go\\bin\""
            ;;
    esac
    
    log ""
    log "Restart your terminal to load the new environment."
}

# ================================
# Main Installation Function
# ================================
main() {
    log "🚀 POSIX-Compliant Universal Go Installer"
    log "=========================================="
    log "Installing Go $GO_VERSION"
    log ""
    
    detect_platform
    validate_permissions
    create_directories
    cleanup_existing
    download_go
    install_go
    setup_environment
    install_dev_tools
    verify_installation
    show_shell_instructions
    
    log ""
    log "🎉 Installation Complete!"
    log "========================"
    log "Go $GO_VERSION is now installed and ready to use."
    log ""
    log "Quick start:"
    log "  mkdir ~/workspace/my-project && cd ~/workspace/my-project"
    log "  go mod init my-project"
    log "  printf 'package main\\nimport \"fmt\"\\nfunc main() { fmt.Println(\"Hello!\") }\\n' > main.go"
    log "  go run main.go"
    log ""
    log "Happy coding! 🎯"
}

# Execute main function
main "$@"
