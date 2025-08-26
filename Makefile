# Makefile for PicoRV32 Rust Hello World Simulation

# Directories
PICORV32_DIR = picorv32
RUST_DIR = $(PICORV32_DIR)/rust-hello-world

# Source files
VERILOG_SOURCES = $(PICORV32_DIR)/picorv32.v $(PICORV32_DIR)/testbench.v

# Output files
SIM_OUTPUT = picorv32_sim
VCD_OUTPUT = testbench.vcd

# Default target
all: simulate

# Build the Rust program and generate hex file
build_rust:
	cd $(RUST_DIR) && . "$$HOME/.cargo/env" && cargo build --release
	cd $(RUST_DIR) && . "$$HOME/.cargo/env" && cargo objcopy --release -- -O binary hello_world.bin
	python3 bin_to_hex.py $(RUST_DIR)/hello_world.bin hello_world.hex

# Compile the Verilog design
compile: build_rust
	iverilog -g2012 -o $(SIM_OUTPUT) $(VERILOG_SOURCES)

# Run the simulation
simulate: compile
	vvp $(SIM_OUTPUT)

# Run simulation with VCD output
simulate_vcd: compile
	vvp $(SIM_OUTPUT) +vcd

# View the waveform (requires GTKWave)
view_wave: $(VCD_OUTPUT)
	gtkwave $(VCD_OUTPUT) &

# Clean up generated files
clean:
	rm -f $(SIM_OUTPUT) $(VCD_OUTPUT) hello_world.hex
	cd $(RUST_DIR) && cargo clean

.PHONY: all build_rust compile simulate simulate_vcd view_wave clean
