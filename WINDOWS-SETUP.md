# Windows Setup - WSL2 and Ubuntu

## Install WSL2 with Ubuntu for Backend Development

This guide installs Windows Subsystem for Linux (WSL2) with Ubuntu to provide a POSIX-compliant development environment identical to Ubuntu and macOS systems.

## Prerequisites
- Windows 10 version 2004+ or Windows 11
- Administrator access
- Git for Windows

## Step 1: Install Git for Windows
Download and install: https://git-scm.com/download/win

Accept all default settings during installation.

## Step 2: Install WSL2 with Ubuntu
```powershell
# Run PowerShell as Administrator
wsl --install -d Ubuntu-24.04
```

If Ubuntu 24.04 is not available:
```powershell
# Fallback to Ubuntu 22.04
wsl --install -d Ubuntu-22.04
```

## Step 3: Restart Computer
Restart Windows to complete WSL installation.

## Step 4: Configure Ubuntu
1. Open "Ubuntu" from Start Menu
2. Create username and password when prompted
3. Update system packages:
```bash
sudo apt update && sudo apt upgrade -y
sudo apt install -y curl wget git build-essential
```

## Step 5: Configure Git in Ubuntu
```bash
git config --global user.name "Your Name"
git config --global user.email "your.email@example.com"

# Optional: Set up SSH key for GitHub
ssh-keygen -t ed25519 -C "your.email@example.com"
cat ~/.ssh/id_ed25519.pub
# Copy the output and add to GitHub SSH keys
```

## Step 6: Verify Installation
```bash
# Check Ubuntu version
lsb_release -a

# Check Git
git --version

# Check development tools
curl --version
```

## Usage
- Use Ubuntu terminal for all development work
- Access from Start Menu: "Ubuntu"
- Your development environment is now identical to Ubuntu and macOS

## File System Access
- **From Ubuntu to Windows**: `/mnt/c/Users/YourUsername/`
- **From Windows to Ubuntu**: `\\wsl$\Ubuntu-24.04\home\yourusername\`

## Troubleshooting

**WSL command not found?**
- Update Windows to latest version
- Enable virtualization in BIOS/UEFI

**Ubuntu won't start?**
```powershell
wsl --shutdown
wsl --unregister Ubuntu-24.04
wsl --install -d Ubuntu-24.04
```

**Performance issues?**
- Keep development projects in Ubuntu file system (`~/`)
- Avoid working from `/mnt/c/` for active development
