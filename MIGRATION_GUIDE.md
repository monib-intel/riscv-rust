# Migration Guide

This guide helps existing users migrate from the old manual setup to the new Nix-based environment.

## 🔄 What Changed

### Before (Manual Setup)
- Manual Rust installation with `rustup`
- Manual RISC-V toolchain installation
- Python virtual environment with `uv` or `pip`
- Platform-specific dependency management
- `cargo install cargo-binutils` required

### After (Nix Environment)
- Everything provided by Nix declaratively
- Zero external dependencies
- Identical setup across all platforms
- No manual package installation needed

## 🚀 Quick Migration

### 1. Install Nix (if not already installed)
```bash
# Recommended: Determinate Systems installer
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh

# Or official installer
curl -L https://nixos.org/nix/install | sh
```

### 2. Enter the new environment
```bash
# This replaces all the old setup steps
nix develop
```

### 3. Test that everything works
```bash
make regression
```

## 🧹 Cleanup (Optional)

You can now remove old dependencies that are no longer needed:

### Remove Python Virtual Environment
```bash
# Remove old .venv directories
rm -rf .venv projects/*/.venv

# Remove uv if installed only for this project
# (Keep if you use it elsewhere)
```

### Remove Manual Rust Installation
```bash
# Only if you installed Rust specifically for this project
# and don't use it elsewhere
rustup self uninstall
```

### Remove cargo-binutils
```bash
# No longer needed - functionality provided by Nix llvm-tools
cargo uninstall cargo-binutils
```

## 📋 Command Changes

| Old Command | New Command |
|-------------|-------------|
| `make setup-python` | Not needed (deprecated) |
| `cargo install cargo-binutils` | Not needed (included in Nix) |
| `source ~/.cargo/env` | Not needed (handled by Nix) |
| Manual tool installation | `nix develop` |

## 🔧 Workflow Changes

### Old Workflow
```bash
# Check and install dependencies
make check-deps
make setup-python

# Activate environment
source .venv/bin/activate

# Build and test
make build PROJECT=hello-world
make regression
```

### New Workflow
```bash
# Enter complete environment (one command)
nix develop

# Build and test (same commands)
make build PROJECT=hello-world
make regression
```

## 🐛 Troubleshooting Migration

### "Command not found" errors
Make sure you're in the Nix environment:
```bash
nix develop
which cargo  # Should show /nix/store/... path
```

### Old .venv conflicts
Remove any leftover virtual environments:
```bash
find . -name ".venv" -type d -exec rm -rf {} +
```

### Rust target issues
The Nix environment includes the RISC-V target automatically. If you see target errors:
```bash
# Check targets are available
rustup target list --installed
# Should show: riscv32i-unknown-none-elf
```

### PATH issues
In the Nix environment, all tools should be in PATH automatically:
```bash
nix develop
echo $PATH  # Should include all necessary tool paths
```

## ✅ Benefits After Migration

- **Faster setup**: Single `nix develop` command
- **More reliable**: No dependency version conflicts
- **Better reproducibility**: Identical environment everywhere
- **Easier CI/CD**: Simple GitHub Actions setup
- **Less maintenance**: No manual updates needed
- **Cross-platform**: Same commands on Linux, macOS, WSL

## 🆘 Need Help?

If you encounter issues during migration:

1. **Check NIX_SETUP.md** for detailed Nix setup instructions
2. **Run diagnostics**: `nix develop --command make check-deps`
3. **Clean start**: Remove any old build artifacts with `make clean`
4. **Verify environment**: Check that all tools are available in `nix develop`

## 🔄 Rollback Plan

If you need to temporarily go back to the old setup:

1. **Keep the old branch**: Create a branch before migrating
2. **Restore tools**: Reinstall Rust/Python tools if removed
3. **Use old commands**: The old Makefile targets still work outside Nix

However, we recommend persisting with the Nix setup as it's more reliable and maintainable long-term.
