# Makefile for PicoRV32 with Rust Hello World

RV32I_PREFIX ?= riscv32-unknown-elf-
RUST_TARGET = riscv32i-unknown-none-elf

RTL_DIR = rtl
RUST_DIR = rust-hello-world

.PHONY: all clean rust picorv32 sim

all: picorv32 rust sim

# Build the Rust Hello World program
rust:
	cd $(RUST_DIR) && make RISCV_PREFIX=$(RV32I_PREFIX)

# Get PicoRV32 core
picorv32:
	test -d $(RTL_DIR) || mkdir -p $(RTL_DIR)
	test -f $(RTL_DIR)/picorv32.v || \
		curl -o $(RTL_DIR)/picorv32.v https://raw.githubusercontent.com/YosysHQ/picorv32/master/picorv32.v
	test -f picorv32.v || \
		cp -f $(RTL_DIR)/picorv32.v ./picorv32.v

# Run simulation
sim: picorv32 rust
	iverilog -o sim.vvp -s testbench testbench.v $(RTL_DIR)/picorv32.v
	vvp sim.vvp +vcd

# Clean up
clean:
	cd $(RUST_DIR) && make clean
	rm -f *.vvp *.vcd
	rm -f sim.vvp testbench.vcd
