# RISC-V Rust Development Environment

A fully self-contained development environment for simulating Rust programs on RISC-V processor cores using Nix.

## 🚀 Quick Start

### Option 1: Using Nix (Recommended)

```bash
# Enter the development environment
nix develop

# Run the hello-world example
make example

# Run regression tests
make regression
```

### Option 2: Traditional Setup

```bash
# Check dependencies
make check-deps

# Run the hello-world example
make example
```

## 📁 Project Structure

```
riscv-rust/
├── flake.nix             # Nix development environment
├── Makefile              # Build system
├── README.md             # This file
├── NIX_SETUP.md          # Detailed Nix setup guide
├── projects/             # Rust projects
│   └── hello-world/      # Example project
├── cores/                # RISC-V core implementations
│   └── picorv32/         # PicoRV32 core
├── tools/                # Python utilities
│   ├── project_manager.py
│   ├── regression.py
│   ├── run_regression.py
│   └── simulator.py
├── tests/                # Regression test suite
└── output/               # Build and simulation outputs
```

## 🔧 Environment Setup

### Nix Flakes (Recommended)

This project uses Nix Flakes to provide a fully reproducible development environment with **zero external dependencies**.

#### Prerequisites
- [Nix](https://nixos.org/download.html) with [Flakes](https://nixos.wiki/wiki/Flakes) enabled

#### Usage
```bash
# Enter the development shell (installs all dependencies automatically)
nix develop

# Or run commands directly
nix develop --command make build PROJECT=hello-world
```

The Nix environment includes:
- ✅ Rust nightly with RISC-V target (`riscv32i-unknown-none-elf`)
- ✅ RISC-V GNU toolchain (with intelligent fallbacks)
- ✅ LLVM tools for binary manipulation
- ✅ Icarus Verilog for simulation
- ✅ Python with all testing dependencies (pytest, pyyaml, rich, etc.)
- ✅ All build tools (make, pkg-config, etc.)

### Traditional Setup

If you prefer not to use Nix, you'll need to install these dependencies manually:

- Rust toolchain with RISC-V target
- RISC-V GNU Toolchain or LLVM tools
- Icarus Verilog (iverilog)
- Python 3 with pytest and pyyaml

## 🎯 Makefile Targets

### Project Management
- `make list-projects` - List all projects
- `make project-info PROJECT=name` - Show project information

### Building and Simulation
- `make build PROJECT=name` - Build a project
- `make simulate PROJECT=name CORE=name` - Simulate a project
- `make example` - Run the hello-world example

### Core Management
- `make list-cores` - List available cores
- `make core-info CORE=name` - Show core information

### Testing
- `make regression` - Run comprehensive regression tests
- `make test-hello-world` - Run the hello-world test

### Utilities
- `make clean` - Clean build artifacts
- `make help` - Show help message

## 🖥️ RISC-V Cores

Currently supported cores:

- **PicoRV32**: A small, configurable RISC-V CPU implementation

## 🧪 Testing

The project includes a comprehensive test suite:

```bash
# Run all tests
make regression

# Run specific project test
make test-hello-world

# Run tests with verbose output
nix develop --command python3 tools/run_regression.py -v
```

## 🔧 Development Workflow

1. **Enter the environment**: `nix develop`
2. **Create a new project** in `projects/`
3. **Build your project**: `make build PROJECT=your-project`
4. **Simulate**: `make simulate PROJECT=your-project CORE=picorv32`
5. **Test**: Add tests in `tests/` and run `make regression`

## 📚 Additional Documentation

- [NIX_SETUP.md](NIX_SETUP.md) - Detailed Nix setup and troubleshooting
- [REGRESSION_TESTING.md](REGRESSION_TESTING.md) - Testing framework documentation

## 🔄 GitHub Actions

This repository is fully compatible with GitHub Actions using the provided Nix environment:

```yaml
- name: Build and test
  run: |
    nix develop --command make build PROJECT=hello-world
    nix develop --command make regression
```

## 🤝 Contributing

1. Fork the repository
2. Use `nix develop` to enter the development environment
3. Make your changes
4. Run `make regression` to ensure tests pass
5. Submit a pull request

## 📄 License

This project is open source. See individual core licenses for their respective terms.

---

**Note**: This environment is designed to be fully self-contained when using Nix. All dependencies are declaratively managed and reproducible across different systems.
