#!/bin/sh
# Clean Go Installer - ONLY installs Go binary, asks for user input

set -e

GO_VERSION="1.24.4"
INSTALL_DIR="$HOME/.local"
GO_DIR="$INSTALL_DIR/go"

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

detect_platform() {
    OS=$(uname -s)
    MACHINE=$(uname -m)
    
    case "$OS" in
        Linux*)
            PLATFORM="linux"
            ARCH="amd64"
            log "Platform: Linux"
            ;;
        Darwin*)
            PLATFORM="darwin"
            case "$MACHINE" in
                arm64) ARCH="arm64"; log "Platform: macOS (Apple Silicon)" ;;
                x86_64) ARCH="amd64"; log "Platform: macOS (Intel)" ;;
                *) error "Unsupported macOS architecture: $MACHINE" ;;
            esac
            ;;
        *) error "Unsupported platform: $OS" ;;
    esac
}

show_current_state() {
    log ""
    log "🔍 Current Go Status:"
    log "===================="
    
    if command_exists go; then
        GO_BINARY=$(command -v go)
        GO_VERSION_CURRENT=$(go version 2>/dev/null | cut -d' ' -f3 2>/dev/null || echo "unknown")
        GO_ROOT_CURRENT=$(go env GOROOT 2>/dev/null || echo "unknown")
        GO_PATH_CURRENT=$(go env GOPATH 2>/dev/null || echo "unknown")
        
        log "✓ Go is installed:"
        log "  Binary: $GO_BINARY"
        log "  Version: $GO_VERSION_CURRENT"  
        log "  GOROOT: $GO_ROOT_CURRENT"
        log "  GOPATH: $GO_PATH_CURRENT"
    else
        log "✗ Go not found in PATH"
    fi
    
    log ""
    log "Environment Variables:"
    log "PATH: $PATH"
    log "GOROOT: ${GOROOT:-not set}"
    log "GOPATH: ${GOPATH:-not set}"
    
    log ""
    log "Target Installation:"
    log "Will install Go $GO_VERSION to: $GO_DIR"
}

get_user_choice() {
    show_current_state
    
    log ""
    log "⚠️  This script will install Go $GO_VERSION"
    log "Target location: $GO_DIR"
    log ""
    log "Options:"
    log "1) Proceed with installation"
    log "2) Exit without changes"
    log ""
    
    while true; do
        printf "Enter your choice (1 or 2): "
        read choice
        
        case "$choice" in
            1)
                log "Proceeding with installation..."
                return 0
                ;;
            2)
                log "Installation cancelled"
                exit 0
                ;;
            *)
                log "Invalid choice. Please enter 1 or 2."
                ;;
        esac
    done
}

install_go() {
    log ""
    log "📦 Installing Go $GO_VERSION..."
    
    # Remove existing if present
    if [ -d "$GO_DIR" ]; then
        log "Removing existing installation..."
        rm -rf "$GO_DIR"
    fi
    
    # Create directory
    mkdir -p "$INSTALL_DIR"
    
    # Download
    FILENAME="go${GO_VERSION}.${PLATFORM}-${ARCH}.tar.gz"
    DOWNLOAD_URL="https://golang.org/dl/$FILENAME"
    
    cd /tmp
    rm -f "$FILENAME" 2>/dev/null || true
    
    log "Downloading: $DOWNLOAD_URL"
    if command_exists curl; then
        curl -L "$DOWNLOAD_URL" -o "$FILENAME" || error "Download failed"
    elif command_exists wget; then
        wget "$DOWNLOAD_URL" -O "$FILENAME" || error "Download failed"
    else
        error "Neither curl nor wget found"
    fi
    
    # Extract
    log "Extracting..."
    tar -C "$INSTALL_DIR" -xzf "$FILENAME" || error "Extraction failed"
    rm -f "$FILENAME"
    
    # Verify
    if [ ! -f "$GO_DIR/bin/go" ]; then
        error "Installation failed"
    fi
    
    log "✅ Go installed successfully"
    "$GO_DIR/bin/go" version
}

setup_environment() {
    log ""
    log "⚙️  Setting up environment..."
    
    cat > "$HOME/.profile" << 'EOF'
# Go environment
if [ -d "$HOME/.local/go" ]; then
    export GOROOT="$HOME/.local/go"
    export PATH="$GOROOT/bin:$PATH"
fi
export GOPATH="$HOME/go"
export PATH="$PATH:$GOPATH/bin"
EOF

    log "✅ Environment configured"
    log "Run: source ~/.profile"
}

main() {
    log "🚀 Go Installer (Binary Only)"
    log "============================="
    log "This script ONLY installs Go - no development tools"
    log ""
    
    detect_platform
    get_user_choice
    install_go
    setup_environment
    
    log ""
    log "🎉 Installation complete!"
    log "Run: source ~/.profile && go version"
}

main "$@"
