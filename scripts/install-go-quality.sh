#!/bin/sh
set -e

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

main() {
    log "Go Quality Tools Installer"
    log ""
    
    command_exists go || error "Go not found. Run install-go.sh first."
    
    log "Current Go: $(go version)"
    log ""
    
    log "Will install:"
    log "- gopls (language server)"
    log "- goimports (import formatter)" 
    log "- staticcheck (static analyzer)"
    log "- godoc (documentation)"
    log ""
    
    printf "Continue? (y/n): "
    read answer
    
    case "$answer" in
        y|Y|yes|YES)
            log "Installing tools..."
            ;;
        *)
            log "Cancelled"
            exit 0
            ;;
    esac
    
    log "Installing gopls..."
    go install golang.org/x/tools/gopls@latest
    
    log "Installing goimports..."
    go install golang.org/x/tools/cmd/goimports@latest
    
    log "Installing staticcheck..."
    go install honnef.co/go/tools/cmd/staticcheck@latest
    
    log "Installing godoc..."
    go install golang.org/x/tools/cmd/godoc@latest
    
    log ""
    log "Verifying installation:"
    
    if command_exists gopls; then
        log "✓ gopls: $(command -v gopls)"
    else
        log "✗ gopls failed"
    fi
    
    if command_exists goimports; then
        log "✓ goimports: $(command -v goimports)"
    else
        log "✗ goimports failed"
    fi
    
    if command_exists staticcheck; then
        log "✓ staticcheck: $(command -v staticcheck)"
    else
        log "✗ staticcheck failed"
    fi
    
    if command_exists godoc; then
        log "✓ godoc: $(command -v godoc)"
    else
        log "✗ godoc failed"
    fi
    
    log ""
    log "Installation complete!"
}

main "$@"
