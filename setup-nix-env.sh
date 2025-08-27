#!/usr/bin/env bash
# Script to set up the Nix development environment for RISC-V Rust

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}RISC-V Rust Development Environment Setup${NC}"
echo "----------------------------------------"

# Check if Nix is installed
if ! command -v nix &> /dev/null; then
    echo -e "${YELLOW}Nix is not installed. Would you like to install it? (y/n)${NC}"
    read -r answer
    if [[ "$answer" =~ ^[Yy]$ ]]; then
        echo -e "${GREEN}Installing Nix...${NC}"
        curl -L https://nixos.org/nix/install | sh
        
        # Source nix if it was just installed
        if [ -e ~/.nix-profile/etc/profile.d/nix.sh ]; then
            . ~/.nix-profile/etc/profile.d/nix.sh
        fi
    else
        echo -e "${RED}Nix is required for this development environment.${NC}"
        echo "Please install Nix manually: https://nixos.org/download.html"
        exit 1
    fi
fi

# Check if flakes are enabled
if ! nix flake --help &> /dev/null; then
    echo -e "${YELLOW}Nix Flakes not enabled. Would you like to enable them? (y/n)${NC}"
    read -r answer
    if [[ "$answer" =~ ^[Yy]$ ]]; then
        mkdir -p ~/.config/nix
        echo "experimental-features = nix-command flakes" >> ~/.config/nix/nix.conf
        echo -e "${GREEN}Enabled Nix Flakes. You may need to restart your terminal.${NC}"
    else
        echo -e "${YELLOW}Using traditional nix-shell instead of flakes...${NC}"
        nix-shell
        exit $?
    fi
fi

# Check if direnv is installed and offer to install it
if ! command -v direnv &> /dev/null; then
    echo -e "${YELLOW}direnv is not installed. Would you like to install it? (y/n)${NC}"
    echo "direnv makes it easier to automatically activate the environment when you enter the directory."
    read -r answer
    if [[ "$answer" =~ ^[Yy]$ ]]; then
        nix profile install nixpkgs#direnv
        echo -e "${GREEN}Installed direnv.${NC}"
        echo "You need to add the following to your shell config (~/.bashrc, ~/.zshrc, etc.):"
        echo 'eval "$(direnv hook bash)"  # or zsh/fish depending on your shell'
        echo "Then restart your shell and run 'direnv allow' in this directory."
    fi
fi

# Enter the development shell
echo -e "${GREEN}Starting Nix development shell...${NC}"
echo "This may take a few minutes the first time as it downloads dependencies."
nix develop

# If nix develop failed, try nix-shell as fallback
if [ $? -ne 0 ]; then
    echo -e "${YELLOW}Falling back to nix-shell...${NC}"
    nix-shell
fi
