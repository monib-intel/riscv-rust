# README: Rust on PicoRV32 RISC-V Processor

This project demonstrates how to compile and run a Rust hello-world program on the PicoRV32 RISC-V processor.

## What is PicoRV32?

PicoRV32 is a size-optimized RISC-V CPU implementation written in Verilog. It implements the RISC-V RV32I instruction set and can be configured for various extensions.

## Directory Structure

- `rtl/` - RTL files for the PicoRV32 processor core
- `rust-hello-world/` - Rust hello-world application for PicoRV32
- `firmware/` - Example C programs from the PicoRV32 repository (for reference)
- `picosoc/` - Simple SoC example from the PicoRV32 repository (for reference)

## Setup Instructions

1. Run the setup script to clone the PicoRV32 repository and set up Rust:

```
chmod +x setup.csh
./setup.csh
```

2. Build the Rust hello-world application and the RTL with the Makefile:

```
make
```

## Components

### 1. PicoRV32 Processor

The PicoRV32 processor is a small RISC-V implementation that we use as our hardware platform. Key features:

- Small size (750-2000 LUTs in Xilinx 7-Series)
- High fmax (250-450 MHz on Xilinx 7-Series)
- Simple memory interface
- RV32I instruction set support

### 2. Rust Hello World

The Rust hello-world application is a minimal bare-metal program that:

- Initializes the stack
- Outputs "Hello, World" via a memory-mapped UART
- Runs in an infinite loop

## Simulation

The project includes a testbench for simulating the Rust program on the PicoRV32 processor. The simulation:

1. Loads the compiled Rust program into memory
2. Initializes the PicoRV32 processor
3. Runs the simulation and captures UART output
4. Generates VCD waveforms for debugging

## Tools Required

- Rust toolchain with RISC-V target support
- Icarus Verilog (for simulation)
- GTKWave (for viewing waveforms)

## Resources

- [PicoRV32 GitHub Repository](https://github.com/YosysHQ/picorv32)
- [Rust Embedded Book](https://docs.rust-embedded.org/book/)
- [RISC-V Specifications](https://riscv.org/technical/specifications/)
