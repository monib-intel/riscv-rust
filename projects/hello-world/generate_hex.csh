#!/bin/csh
# Script to generate hex file from compiled Rust binary for PicoRV32

# Path to the compiled Rust binary
set BINARY_PATH="target/riscv32i-unknown-none-elf/release/picorv32-hello-world"

# Check if binary exists
if (! -e $BINARY_PATH) then
    echo "Error: Binary file not found at $BINARY_PATH"
    echo "Make sure to run 'cargo build --release' first"
    exit 1
endif

# Generate binary file from ELF
echo "Generating binary file from ELF..."
llvm-objcopy -O binary $BINARY_PATH hello_world.bin

# Generate hex file from binary
echo "Generating hex file from binary..."
xxd -p hello_world.bin > hello_world.hex

echo "Hex file generation complete."
echo "Hex file: hello_world.hex"
