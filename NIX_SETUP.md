# Nix/Flakes Development Environment

This project uses Nix Flakes to provide a consistent development environment across different machines.

## Prerequisites

- Install [Nix](https://nixos.org/download.html)
- Enable [Flakes](https://nixos.wiki/wiki/Flakes) (if not already enabled)

## Using the Nix Environment

### Quick Setup Script

The easiest way to get started is to use the setup script:

```bash
# Make it executable if needed
chmod +x setup-nix-env.sh

# Run the setup script
./setup-nix-env.sh
```

The script will guide you through installing Nix and enabling Flakes if needed.

### With Flakes Enabled

```bash
# Enter the development shell
nix develop

# Or run a command in the development shell
nix develop --command make build
```

### Without Flakes (Traditional Nix)

```bash
# Enter the development shell
nix-shell

# Or run a command in the development shell
nix-shell --run "make build"
```

### With direnv

If you have [direnv](https://direnv.net/) installed and the [nix-direnv](https://github.com/nix-community/nix-direnv) extension:

```bash
# Allow the .envrc file (only needed once)
direnv allow

# The environment will load automatically when you enter the directory
```

## Included Tools

The Nix environment provides:

- Rust nightly with RISC-V target
- RISC-V GNU toolchain (automatically finds the right package for your system)
- Icarus Verilog and GTKWave (if available on your platform)
- Python environment with required packages
- All other build dependencies

## Additional Tools

Some tools need to be installed manually inside the development environment:

```bash
# Install cargo-binutils (needed for generating binaries)
cargo install cargo-binutils
```

## Benefits

- Consistent development environment across different machines
- No need to manually install dependencies
- Works on Linux, macOS, and WSL
- Reproducible builds

## Troubleshooting

### "Git tree is dirty" warning

This warning is normal during development and can be safely ignored. It will disappear once you commit your changes.

### Missing package errors

The flake is designed to adapt to different systems and Nixpkgs versions. If a package is not available, it will try to use alternatives or give you instructions on how to install it manually.

## Customizing

To customize the environment, edit the `flake.nix` file and add or remove dependencies as needed.
