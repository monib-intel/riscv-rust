# Nix Development Environment

This project uses Nix Flakes to provide a **fully self-contained** development environment. All dependencies are declaratively managed with zero external setup required.

## 🚀 Quick Start

```bash
# Enter the development shell (installs everything automatically)
nix develop

# Or run commands directly
nix develop --command make example
```

## 📋 Prerequisites

- [Nix](https://nixos.org/download.html) with [Flakes](https://nixos.wiki/wiki/Flakes) enabled

### Installing Nix with Flakes

#### On Linux/macOS/WSL:
```bash
# Install Nix with the determinate installer (recommended)
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh

# Or use the official installer
curl -L https://nixos.org/nix/install | sh
```

#### Enable Flakes:
If using the official installer, enable flakes:
```bash
# Add to ~/.config/nix/nix.conf or /etc/nix/nix.conf
experimental-features = nix-command flakes
```

## 🔧 Using the Development Environment

### Recommended: Direct Usage

```bash
# Enter the development shell
nix develop

# The environment is now active with all dependencies available
make help
```

### Running Commands Directly

```bash
# Build a project
nix develop --command make build PROJECT=hello-world

# Run tests
nix develop --command make regression

# Chain multiple commands
nix develop --command bash -c "make build PROJECT=hello-world && make test-hello-world"
```

### With direnv (Optional)

For automatic environment activation:

1. Install [direnv](https://direnv.net/) and [nix-direnv](https://github.com/nix-community/nix-direnv)
2. Create a `.envrc` file:
   ```bash
   echo "use flake" > .envrc
   direnv allow
   ```
3. The environment will activate automatically when you `cd` into the directory

## 📦 What's Included

The Nix environment provides **everything** needed for development:

### Rust Ecosystem
- **Rust nightly** with RISC-V target (`riscv32i-unknown-none-elf`)
- **llvm-tools** extension for binary manipulation
- **rust-src** for documentation and analysis

### RISC-V Tools
- **RISC-V GNU toolchain** (with intelligent fallbacks across systems)
- **LLVM tools** (`llvm-objcopy`, `llvm-objdump`, etc.)

### Simulation Tools
- **Icarus Verilog** (`iverilog`) for hardware simulation
- **GTKWave** for waveform viewing (if available)

### Python Environment
- **Python 3.13** with a complete testing stack:
  - `pytest` for testing framework
  - `pytest-xdist` for parallel test execution
  - `pyyaml` for configuration parsing
  - `rich` for beautiful terminal output
  - `click` for CLI interfaces
  - `mypy`, `black`, `flake8` for code quality

### Build Tools
- **GNU Make** for build orchestration
- **pkg-config** for library configuration
- **coreutils** and **bash** for shell utilities

## 🎯 Zero External Dependencies

Unlike traditional setups, this environment requires **no external installations**:

- ❌ No manual Rust installation
- ❌ No cargo install commands
- ❌ No Python virtual environments
- ❌ No system package manager dependencies
- ❌ No manual toolchain setup

Everything is provided by Nix and works identically across:
- Linux (x86_64, aarch64)
- macOS (Intel, Apple Silicon)  
- WSL on Windows
- GitHub Actions
- Docker containers

## 🔍 Troubleshooting

### "Git tree is dirty" warning
This warning appears during development and can be safely ignored:
```
warning: Git tree '/path/to/riscv-rust' is dirty
```
It disappears once you commit your changes or use `git stash`.

### Flakes not enabled
If you see `error: experimental Nix feature 'flakes' is disabled`:
```bash
# Add to ~/.config/nix/nix.conf
mkdir -p ~/.config/nix
echo "experimental-features = nix-command flakes" >> ~/.config/nix/nix.conf
```

### Package not available errors
The flake includes intelligent fallbacks for different systems and Nixpkgs versions. If you encounter issues:

1. **Update Nixpkgs**: `nix flake update`
2. **Check system compatibility**: The flake supports x86_64-linux, aarch64-linux, x86_64-darwin, aarch64-darwin
3. **Check specific errors**: Some packages may not be available on certain platforms

### Slow first-time setup
The first run may take longer as Nix downloads and builds dependencies. Subsequent runs are fast due to caching.

## 🛠️ Advanced Usage

### Updating Dependencies
```bash
# Update the flake inputs
nix flake update

# Enter the updated environment
nix develop
```

### Customizing the Environment
Edit `flake.nix` to add or remove dependencies:

```nix
# Add new Python packages
pythonEnv = pkgs.python3.withPackages (ps: with ps; [
  pytest
  # Add your packages here
  numpy
  matplotlib
]);

# Add new system packages
buildInputs = with pkgs; [
  rustToolchain
  # Add your tools here
  git
  vim
];
```

### Using in CI/CD
The environment works perfectly in GitHub Actions:

```yaml
name: CI
on: [push, pull_request]
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: cachix/install-nix-action@v24
        with:
          extra_nix_config: experimental-features = nix-command flakes
      - run: nix develop --command make regression
```

## 📊 Benefits Over Traditional Setup

| Traditional | Nix Environment |
|-------------|-----------------|
| Manual dependency installation | Automatic dependency management |
| Version conflicts | Isolated, reproducible environment |
| Platform-specific setup | Works identically everywhere |
| "Works on my machine" | Guaranteed reproducibility |
| Complex CI setup | Simple, declarative CI |
| Maintenance burden | Self-maintaining dependencies |

## 🔗 Related Resources

- [Nix Manual](https://nixos.org/manual/nix/stable/)
- [Nix Flakes Guide](https://nixos.wiki/wiki/Flakes)
- [Zero to Nix](https://zero-to-nix.com/) - Excellent Nix learning resource
- [Rust Overlay](https://github.com/oxalica/rust-overlay) - Used for Rust toolchains
