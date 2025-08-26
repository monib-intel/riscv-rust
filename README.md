# RISC-V Rust Development Environment

A comprehensive development environment for creating and simulating Rust programs on various RISC-V processor cores.

## 🚀 Quick Start

```bash
# Set up the environment
make setup

# Check dependencies
make check-deps

# Run the hello-world example
make example

# Create a new project
make create-project PROJECT=my-project

# Build and simulate
make simulate PROJECT=my-project
```

## 📁 Project Structure

```
riscv-rust/
├── Makefile              # Top-level build system
├── requirements.txt      # Python dependencies
├── README.md            # This file
├── projects/            # Rust projects
│   └── hello-world/     # Example project
├── cores/               # RISC-V core implementations
│   └── picorv32/        # PicoRV32 core
├── tools/               # Python development tools
│   ├── __init__.py
│   ├── project_manager.py
│   ├── simulator.py
│   └── bin_converter.py
├── build/               # Build artifacts and simulation outputs
├── scripts/             # Additional build scripts
└── .git/               # Git repository
```

## 🛠 Tools

### Project Manager
Manages Rust projects with RISC-V targets.

```bash
# Create a new project
python3 tools/project_manager.py create my-project

# List projects
python3 tools/project_manager.py list

# Get project info
python3 tools/project_manager.py info my-project

# Build a project
python3 tools/project_manager.py build my-project
```

### Simulator Runner
Runs simulations on various RISC-V cores.

```bash
# List available cores
python3 tools/simulator.py list-cores

# Get core information
python3 tools/simulator.py core-info picorv32

# Run simulation
python3 tools/simulator.py run picorv32 path/to/binary.elf
```

### Binary Converter
Converts binary files to hex format for Verilog memory initialization.

```bash
# Convert binary to hex
python3 tools/bin_converter.py input.bin output.hex

# With options
python3 tools/bin_converter.py input.bin output.hex --word-size 4 --endianness little
```

## 🎯 Makefile Targets

### Setup and Dependencies
- `make setup` - Set up the development environment
- `make check-deps` - Check if all dependencies are installed

### Project Management
- `make create-project PROJECT=name` - Create a new project
- `make list-projects` - List all projects
- `make project-info PROJECT=name` - Show project information

### Building
- `make build PROJECT=name` - Build a project
- `make build-all` - Build all projects

### Simulation
- `make simulate PROJECT=name CORE=name` - Simulate a project
- `make simulate-vcd PROJECT=name CORE=name` - Simulate with VCD output

### Testing
- `make run-test PROJECT=name CORE=name` - Run tests for a specific project on a core
- `make test-hello-world` - Run the hello-world example test
- `make test-all` - Run tests for all projects on all cores

### Core Management
- `make list-cores` - List available cores
- `make core-info CORE=name` - Show core information

### Utilities
- `make clean` - Clean build artifacts
- `make clean-all` - Deep clean everything
- `make help` - Show help message

## 🔧 Adding New Cores

To add a new RISC-V core:

1. Create a directory in `cores/`
2. Add Verilog files
3. Create a `core.json` configuration file:

```json
{
  "name": "my-core",
  "description": "My RISC-V Core",
  "verilog_files": [
    "core.v",
    "testbench.v"
  ],
  "simulator": "iverilog",
  "memory": {
    "base_address": "0x00000000",
    "size": "64K"
  },
  "uart": {
    "base_address": "0x02000000"
  }
}
```

## 🦀 Creating Rust Projects

Projects are automatically configured for RISC-V bare-metal development:

- Target: `riscv32i-unknown-none-elf`
- `#![no_std]` and `#![no_main]` attributes
- Memory layout defined in `memory.x`
- Entry point: `_start()` function

Example project structure:
```
projects/my-project/
├── Cargo.toml
├── memory.x
├── project.json
├── .cargo/
│   └── config.toml
└── src/
    └── main.rs
```

## 📋 Dependencies

### Required
- Rust toolchain (nightly)
- RISC-V target: `riscv32i-unknown-none-elf`
- cargo-binutils
- Icarus Verilog (iverilog)
- Python 3

### Optional
- GTKWave (for viewing VCD waveforms)
- VS Code with Rust extensions

## 🔍 Examples

### Hello World
```rust
#![no_std]
#![no_main]

use core::panic::PanicInfo;

const UART_TX_ADDR: usize = 0x02000000;

#[panic_handler]
fn panic(_info: &PanicInfo) -> ! {
    loop {}
}

unsafe fn write_mmio(addr: usize, val: u8) {
    core::ptr::write_volatile(addr as *mut u8, val);
}

fn uart_puts(s: &str) {
    for c in s.bytes() {
        unsafe { write_mmio(UART_TX_ADDR, c); }
    }
}

#[no_mangle]
pub extern "C" fn _start() -> ! {
    uart_puts("Hello, World from Rust on RISC-V!\r\n");
    loop {}
}
```

### Building and Running
```bash
# Create project
make create-project PROJECT=my-example

# Edit src/main.rs with your code

# Build and simulate
make simulate PROJECT=my-example CORE=picorv32

# Generate waveforms
make simulate-vcd PROJECT=my-example CORE=picorv32
```

## � Testing

The environment includes a test framework for validating RISC-V programs:

### Running Tests
```bash
# Run test for a specific project
make run-test PROJECT=my-project CORE=picorv32

# Run the hello-world test
make test-hello-world

# Run all tests
make test-all
```

### Test Framework Features
- Automatic verification of program output
- Captures UART output for validation
- Pass/fail reporting
- Detailed test logs

Tests check for expected patterns in the UART output. The hello-world example
tests for the presence of "Hello" in the output.

## �📈 Future Enhancements

- [ ] Support for more RISC-V cores (NEORV32, VexRiscv, etc.)
- [ ] Integration with FPGA synthesis tools
- [ ] Debug support with GDB
- [ ] Automated testing framework
- [ ] Performance profiling tools
- [ ] Documentation generation
- [ ] CI/CD pipeline integration

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Add your changes
4. Test with existing projects
5. Submit a pull request

## 📝 License

This project is open source. See individual core licenses for their respective terms.

## 🔗 Resources

- [RISC-V International](https://riscv.org/)
- [Rust Embedded Book](https://doc.rust-lang.org/embedded-book/)
- [PicoRV32 GitHub](https://github.com/YosysHQ/picorv32)
- [Icarus Verilog](http://iverilog.icarus.com/)
