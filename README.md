# RISC-V Rust Development Environment

A comprehensive development environment for simulating Rust programs on RISC-V processor cores.

## 🚀 Quick Start

1. Follow the setup instructions in [SETUP.md](SETUP.md) to install dependencies.

2. Activate the Python virtual environment:
```bash
source .venv/bin/activate
```

3. Run the hello-world example:
```bash
make example
```

4. Run regression tests:
```bash
make regression
```

## 📁 Project Structure

```
riscv-rust/
├── Makefile              # Build system
├── README.md             # This file
├── SETUP.md              # Setup instructions
├── PHYSICAL_DESIGN.md    # OpenROAD/OpenPDK integration guide
├── projects/             # Rust projects
│   └── hello-world/      # Example project
├── cores/                # RISC-V core implementations
│   └── picorv32/         # PicoRV32 core
├── tools/                # Python utilities
│   ├── project_manager.py
│   ├── regression.py
│   ├── run_regression.py
│   ├── simulator.py
│   └── physical_design/  # Physical design tools
├── tests/                # Regression test suite
├── physical/             # Physical design outputs
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
- ✅ Physical design tools (OpenROAD, Yosys, KLayout, etc. when available)

### Traditional Setup

If you prefer not to use Nix, you'll need to install these dependencies manually:

- Rust toolchain with RISC-V target
- RISC-V GNU Toolchain or LLVM tools
- Icarus Verilog (iverilog)
- Python 3 with pytest and pyyaml
- For physical design: OpenROAD, Yosys, and a PDK (see PHYSICAL_DESIGN.md)

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

### Physical Design (OpenROAD/OpenPDK)
- `make check-physical-deps` - Check physical design dependencies
- `make setup-physical CORE=name PDK=name` - Set up physical design for a core
- `make run-synthesis CORE=name` - Run synthesis
- `make run-pnr CORE=name` - Run place-and-route
- `make run-signoff CORE=name` - Run signoff
- `make run-physical-flow CORE=name PDK=name` - Run full physical design flow

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
5. **Physical design**: `make run-physical-flow CORE=picorv32`
6. **Test**: Add tests in `tests/` and run `make regression`

## 📚 Additional Documentation

- [NIX_SETUP.md](NIX_SETUP.md) - Detailed Nix setup and troubleshooting
- [NIX_FLAKE_ISSUES.md](NIX_FLAKE_ISSUES.md) - Solutions for Nix flake configuration issues
- [REGRESSION_TESTING.md](REGRESSION_TESTING.md) - Testing framework documentation
- [PHYSICAL_DESIGN.md](PHYSICAL_DESIGN.md) - OpenROAD and OpenPDK integration

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
