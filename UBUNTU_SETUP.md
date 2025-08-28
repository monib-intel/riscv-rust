# Ubuntu 22.04 Setup Guide

This guide will help you set up the RISC-V Rust development environment on Ubuntu 22.04 LTS.

## System Requirements

- Ubuntu 22.04 LTS (Jammy Jellyfish)
- At least 4GB of available disk space
- Internet connection for downloading packages

## Installation Steps

1. **Update System Packages**
```bash
sudo apt-get update
sudo apt-get upgrade
```

2. **Install System Dependencies**
```bash
sudo apt-get install -y \
    python3-venv \
    python3-pip \
    iverilog \
    gcc-riscv64-unknown-elf \
    llvm
```

3. **Install Rust**
```bash
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
source "$HOME/.cargo/env"
rustup target add riscv32i-unknown-none-elf
```

4. **Install UV (Fast Python Package Installer)**
```bash
pip install uv
```

5. **Setup Python Virtual Environment**
```bash
uv venv .venv
source .venv/bin/activate
uv pip install pytest pytest-xdist pytest-cov pyyaml rich click setuptools wheel pathlib
```

## Verification

To verify your setup:

1. **Activate the Virtual Environment**
```bash
source .venv/bin/activate
```

2. **Check Dependencies**
```bash
make check-deps
```

You should see all dependencies marked as found (✅).

3. **Run Regression Tests**
```bash
make regression
```

All tests should pass successfully.

## Troubleshooting

If you encounter any issues:

1. **Missing Python Dependencies**
   - Run `make setup` to reinstall all Python packages
   - Ensure you've activated the virtual environment with `source .venv/bin/activate`

2. **Rust Tools Not Found**
   - Run `source "$HOME/.cargo/env"` to update your PATH
   - Verify installation with `rustc --version`

3. **RISC-V Tools Not Found**
   - Verify installation with `riscv64-unknown-elf-gcc --version`
   - If missing, reinstall with `sudo apt-get install --reinstall gcc-riscv64-unknown-elf`

4. **Icarus Verilog Issues**
   - Verify installation with `iverilog -V`
   - If missing, reinstall with `sudo apt-get install --reinstall iverilog`

## Uninstallation

To remove all installed components:

```bash
# Remove system packages
sudo apt-get remove python3-venv python3-pip iverilog gcc-riscv64-unknown-elf llvm

# Remove Rust
rustup self uninstall

# Remove Python virtual environment
rm -rf .venv

# Remove UV
pip uninstall uv
```
