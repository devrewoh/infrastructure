# Infrastructure Scripts

Development environment setup scripts with focused, single-purpose design.

## Scripts

### Core Installation
- `scripts/install-go.sh` - POSIX-compliant Go installer
  - Installs Go 1.24.4 binary only
  - Cross-platform: Linux, macOS, Windows/WSL
  - Shows current Go status and environment
  - User confirmation before installation
  - Clean, focused: **Go installation only**

## Philosophy

**Single Responsibility**: Each script does one thing well.
- Focused functionality
- User confirmation and transparency  
- Easy to maintain and debug
- Choose exactly what you need

## Usage

### Install Go
```bash
cd infrastructure
./scripts/install-go.sh

# Follow prompts, then:
source ~/.profile
go version
