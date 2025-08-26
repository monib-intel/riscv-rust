#!/bin/csh
# Script to download the PicoRV32 RTL and set up the Rust environment

# Clone the PicoRV32 repository
git clone https://github.com/YosysHQ/picorv32.git /nfs/site/disks/ad_user_mahmed601/exploration/rust-riscv/picorv32-repo

# Copy the main Verilog file to our RTL directory
cp /nfs/site/disks/ad_user_mahmed601/exploration/rust-riscv/picorv32-repo/picorv32.v /nfs/site/disks/ad_user_mahmed601/exploration/rust-riscv/picorv32/rtl/

# Copy some useful files for reference
cp -r /nfs/site/disks/ad_user_mahmed601/exploration/rust-riscv/picorv32-repo/firmware /nfs/site/disks/ad_user_mahmed601/exploration/rust-riscv/picorv32/
cp -r /nfs/site/disks/ad_user_mahmed601/exploration/rust-riscv/picorv32-repo/picosoc /nfs/site/disks/ad_user_mahmed601/exploration/rust-riscv/picorv32/

# Set up Rust for RISC-V
rustup default nightly
rustup target add riscv32i-unknown-none-elf
cargo install cargo-binutils

# Build the Rust hello world project
cd /nfs/site/disks/ad_user_mahmed601/exploration/rust-riscv/picorv32/rust-hello-world
cargo build --release

# Create a hex file for the PicoRV32 memory
cargo objcopy --release -- -O binary hello_world.bin
xxd -p hello_world.bin > hello_world.hex
