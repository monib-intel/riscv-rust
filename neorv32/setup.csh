#!/bin/csh
# Clone the NEORV32 repository
git clone --recursive https://github.com/stnolting/neorv32.git /nfs/site/disks/ad_user_mahmed601/exploration/rust-riscv/neorv32-repo

# Once cloned, copy the RTL files to our project
cp -r /nfs/site/disks/ad_user_mahmed601/exploration/rust-riscv/neorv32-repo/rtl/* /nfs/site/disks/ad_user_mahmed601/exploration/rust-riscv/neorv32/rtl/

# Copy some examples for reference
mkdir -p /nfs/site/disks/ad_user_mahmed601/exploration/rust-riscv/neorv32/examples
cp -r /nfs/site/disks/ad_user_mahmed601/exploration/rust-riscv/neorv32-repo/sw/example/hello_world /nfs/site/disks/ad_user_mahmed601/exploration/rust-riscv/neorv32/examples/

# Set up Rust for RISC-V
rustup default nightly
rustup target add riscv32imac-unknown-none-elf
cargo install cargo-binutils

# Build the Rust hello world project
cd /nfs/site/disks/ad_user_mahmed601/exploration/rust-riscv/neorv32/rust-hello-world
cargo build --release

# Generate binary file from ELF
cargo objcopy --release -- -O binary hello_world.bin
