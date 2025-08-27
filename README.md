# RISC-V Rust Development Environment

A lightweight development environment for simulating Rust programs on RISC-V processor cores.

## Quick Start

```bash
# Check dependencies
make check-deps

# Set up Python environment
make setup-python

# Run the hello-world example
make example

# Run regression tests
make regression
```

## Project Structure

```
riscv-rust/
├── Makefile              # Build system
├── requirements.txt      # Python dependencies
├── README.md             # This file
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

## Makefile Targets

### Project Management
- `make list-projects` - List all projects
- `make project-info PROJECT=name` - Show project information

### Building
- `make build PROJECT=name` - Build a project

### Simulation
- `make simulate PROJECT=name CORE=name` - Simulate a project

### Core Management
- `make list-cores` - List available cores
- `make core-info CORE=name` - Show core information

### Testing
- `make regression` - Run regression tests
- `make test-hello-world` - Run the hello-world test

### Utilities
- `make clean` - Clean build artifacts
- `make help` - Show help message

## Dependencies

- Rust toolchain with RISC-V target
- RISC-V GNU Toolchain (for objcopy)
- Icarus Verilog (iverilog)
- Python 3 with pytest

## RISC-V Cores

This environment currently supports:

- PicoRV32: A small RISC-V CPU implementation

## License

This project is open source. See individual core licenses for their respective terms.
