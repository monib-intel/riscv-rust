# README: Rust on NEORV32 RISC-V Processor

This project demonstrates how to compile and run a Rust hello-world program on the NEORV32 RISC-V processor.

## Directory Structure

- `rtl/` - RTL files for the NEORV32 processor core
- `rust-hello-world/` - Rust hello-world application for NEORV32
- `examples/` - Example programs from the NEORV32 repository

## Setup Instructions

1. Run the setup script to clone the NEORV32 repository and set up Rust:

```
chmod +x setup.csh
./setup.csh
```

2. Build the Rust hello-world application:

```
cd rust-hello-world
cargo build --release
```

3. Generate binary file:

```
cargo objcopy --release -- -O binary hello_world.bin
```

## Hardware Implementation

To implement the NEORV32 processor on an FPGA:

1. Use the RTL files in the `rtl/` directory
2. Configure the processor with at least UART0 enabled
3. Use the `hello_world.bin` file to initialize the processor's boot memory

## QEMU Simulation

You can simulate the NEORV32 with QEMU (if the neorv32 machine is supported):

```
qemu-system-riscv32 -machine neorv32 -nographic -serial stdio -kernel target/riscv32imac-unknown-none-elf/release/neorv32-hello-world
```

## Tools Required

- Rust toolchain with RISC-V target support
- RISC-V GCC toolchain (for reference examples)
- QEMU with RISC-V support
- FPGA toolchain (Xilinx Vivado, Intel Quartus, etc.) for hardware implementation

## Resources

- [NEORV32 Documentation](https://stnolting.github.io/neorv32/)
- [Rust Embedded Book](https://docs.rust-embedded.org/book/)
- [RISC-V Specifications](https://riscv.org/technical/specifications/)
