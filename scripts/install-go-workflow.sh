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
    log "Go Workflow Tools Installer"
    log ""
    
    command_exists go || error "Go not found. Run install-go.sh first."
    
    log "Current Go: $(go version)"
    log ""
    
    log "Will install workflow tools:"
    log "- air (live reload for web development)"
    log "- dlv (delve debugger for complex debugging)"
    log "- golangci-lint (comprehensive linter suite)"
    log ""
    log "These are convenience tools for development workflow."
    log "Not essential for learning Go fundamentals."
    log ""
    
    printf "Continue? (y/n): "
    read answer
    
    case "$answer" in
        y|Y|yes|YES)
            log "Installing workflow tools..."
            ;;
        *)
            log "Cancelled"
            exit 0
            ;;
    esac
    
    log "Installing air..."
    go install github.com/air-verse/air@latest
    
    log "Installing delve..."
    go install github.com/go-delve/delve/cmd/dlv@latest
    
    log "Installing golangci-lint..."
    go install github.com/golangci/golangci-lint/cmd/golangci-lint@latest
    
    log ""
    log "Verifying installation:"
    
    if command_exists air; then
        log "✓ air: $(command -v air)"
    else
        log "✗ air failed"
    fi
    
    if command_exists dlv; then
        log "✓ dlv: $(command -v dlv)"
    else
        log "✗ dlv failed"
    fi
    
    if command_exists golangci-lint; then
        log "✓ golangci-lint: $(command -v golangci-lint)"
    else
        log "✗ golangci-lint failed"
    fi
    
    log ""
    log "Workflow tools installed!"
    log ""
    log "Usage examples:"
    log "air                    # Live reload (in web project directory)"
    log "dlv debug              # Debug current package"
    log "golangci-lint run      # Run comprehensive linting"
    log ""
    log "Note: Start with staticcheck for learning."
    log "Use these tools when you need advanced workflow features."
}

main "$@"
