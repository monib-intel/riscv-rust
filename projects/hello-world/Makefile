TARGET = riscv32i-unknown-none-elf
RUST_TARGET_DIR = target/$(TARGET)/release
RUSTFLAGS = "-C link-arg=-Tmemory.x"
RISCV_PREFIX ?= riscv32-unknown-elf-

.PHONY: all clean build

all: build

build:
	# Compile the assembly startup file
	$(RISCV_PREFIX)gcc -c src/asm/start.S -o start.o
	
	# Build Rust project with custom target
	RUSTFLAGS=$(RUSTFLAGS) cargo build --release --target $(TARGET)
	
	# Link with our startup assembly
	$(RISCV_PREFIX)ld -T memory.x start.o $(RUST_TARGET_DIR)/rust-hello-world.o -o $(RUST_TARGET_DIR)/firmware.elf
	
	# Generate binary
	llvm-objcopy -O binary $(RUST_TARGET_DIR)/firmware.elf $(RUST_TARGET_DIR)/firmware.bin
	
	# Generate hex file for simulation
	xxd -p -c 4 $(RUST_TARGET_DIR)/firmware.bin > $(RUST_TARGET_DIR)/firmware.hex
	
	# Show size information
	$(RISCV_PREFIX)size $(RUST_TARGET_DIR)/firmware.elf

clean:
	rm -f start.o
	cargo clean
