#!/bin/bash
# Script to download the PicoRV32 RTL and set up the Rust environment

# Set up paths based on current location
WORKSPACE_DIR="$(pwd)"
PICORV32_DIR="${WORKSPACE_DIR}/picorv32"
REPO_DIR="${WORKSPACE_DIR}/picorv32-repo"

# Clone the PicoRV32 repository if it doesn't exist
if [ ! -d "${REPO_DIR}" ]; then
  git clone https://github.com/YosysHQ/picorv32.git "${REPO_DIR}"
fi

# Copy the main Verilog file to our RTL directory
mkdir -p "${PICORV32_DIR}/rtl"
cp "${REPO_DIR}/picorv32.v" "${PICORV32_DIR}/rtl/"

# Copy some useful files for reference if they don't exist
if [ ! -d "${PICORV32_DIR}/firmware" ]; then
  cp -r "${REPO_DIR}/firmware" "${PICORV32_DIR}/"
fi
if [ ! -d "${PICORV32_DIR}/picosoc" ]; then
  cp -r "${REPO_DIR}/picosoc" "${PICORV32_DIR}/"
fi

# Set up Rust for RISC-V
source "$HOME/.cargo/env"
rustup default nightly
rustup target add riscv32i-unknown-none-elf
cargo install cargo-binutils

# Build the Rust hello world project
cd "${PICORV32_DIR}/rust-hello-world"
cargo build --release

# Create a hex file for the PicoRV32 memory
cargo objcopy --release -- -O binary hello_world.bin
xxd -p hello_world.bin > hello_world.hex

# Copy the hex file to the workspace root for easy access
cp hello_world.hex "${WORKSPACE_DIR}/"

echo "Setup complete. The hello_world.hex file is ready for simulation."
