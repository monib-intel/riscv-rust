# RISC-V Rust Development Environment
# ===================================

SHELL := /bin/bash
.DEFAULT_GOAL := help

# Directories
PROJECTS_DIR := projects
CORES_DIR := cores
TOOLS_DIR := tools
OUTPUT_DIR := output
BUILD_DIR := $(OUTPUT_DIR)/build
SCRIPTS_DIR := scripts

# Python interpreter
PYTHON := python3

# Tools
PROJECT_MANAGER := $(PYTHON) $(TOOLS_DIR)/project_manager.py
SIMULATOR := $(PYTHON) $(TOOLS_DIR)/simulator.py

# Default values
PROJECT ?= hello-world
CORE ?= picorv32
RELEASE ?= true

## Help system
.PHONY: help
help: ## Show this help message
	@echo "RISC-V Rust Development Environment"
	@echo "==================================="
	@echo ""
	@echo "Available targets:"
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)
	@echo ""
	@echo "Variables:"
	@echo "  PROJECT  - Project name (default: $(PROJECT))"
	@echo "  CORE     - Core name (default: $(CORE))"
	@echo "  RELEASE  - Build in release mode (default: $(RELEASE))"
	@echo ""
	@echo "Examples:"
	@echo "  make create-project PROJECT=my-project"
	@echo "  make build PROJECT=my-project"
	@echo "  make simulate PROJECT=my-project CORE=picorv32"

## Setup and initialization
.PHONY: setup
setup: ## Set up the development environment
	@echo "Setting up RISC-V Rust development environment..."
	@mkdir -p $(PROJECTS_DIR) $(CORES_DIR) $(OUTPUT_DIR) $(BUILD_DIR) $(SCRIPTS_DIR)
	@if ! command -v rustup >/dev/null 2>&1; then \
		echo "Installing Rust..."; \
		curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y; \
		. "$$HOME/.cargo/env"; \
	fi
	@. "$$HOME/.cargo/env" && rustup default nightly
	@. "$$HOME/.cargo/env" && rustup target add riscv32i-unknown-none-elf
	@. "$$HOME/.cargo/env" && cargo install cargo-binutils
	@if ! command -v iverilog >/dev/null 2>&1; then \
		echo "Please install Icarus Verilog: sudo apt-get install iverilog"; \
	fi
	@if ! command -v riscv64-unknown-elf-objcopy >/dev/null 2>&1 && \
		! command -v riscv32-unknown-elf-objcopy >/dev/null 2>&1 && \
		! command -v riscv-none-embed-objcopy >/dev/null 2>&1 && \
		! command -v riscv-none-elf-objcopy >/dev/null 2>&1 && \
		! command -v riscv-objcopy >/dev/null 2>&1 && \
		! command -v llvm-objcopy >/dev/null 2>&1; then \
		echo "Please install RISC-V GNU toolchain:"; \
		echo "  Ubuntu/Debian: sudo apt-get install gcc-riscv64-unknown-elf"; \
		echo "  Arch Linux: sudo pacman -S riscv64-elf-binutils"; \
		echo "  macOS: brew install riscv-gnu-toolchain"; \
		echo "  or get prebuilt binaries from https://github.com/riscv-collab/riscv-gnu-toolchain"; \
	fi
	@echo "Setup complete!"

.PHONY: check-deps
check-deps: ## Check if all dependencies are installed
	@echo "Checking dependencies..."
	@command -v rustup >/dev/null 2>&1 || (echo "❌ Rust not found" && exit 1)
	@command -v iverilog >/dev/null 2>&1 || (echo "❌ Icarus Verilog not found" && exit 1)
	@command -v $(PYTHON) >/dev/null 2>&1 || (echo "❌ Python 3 not found" && exit 1)
	@if command -v riscv64-unknown-elf-objcopy >/dev/null 2>&1; then \
		echo "✅ RISC-V GNU tools found"; \
	elif command -v riscv32-unknown-elf-objcopy >/dev/null 2>&1; then \
		echo "✅ RISC-V GNU tools found"; \
	elif command -v riscv-none-embed-objcopy >/dev/null 2>&1; then \
		echo "✅ RISC-V GNU tools found"; \
	elif command -v riscv-none-elf-objcopy >/dev/null 2>&1; then \
		echo "✅ RISC-V GNU tools found"; \
	elif command -v riscv-objcopy >/dev/null 2>&1; then \
		echo "✅ RISC-V GNU tools found"; \
	elif command -v llvm-objcopy >/dev/null 2>&1; then \
		echo "✅ LLVM tools found (preferred for RISC-V)"; \
	else \
		echo "⚠️ No RISC-V binary tools found. Install riscv-gnu-toolchain or LLVM for better compatibility."; \
	fi
	@echo "✅ All dependencies found"

## Project management
.PHONY: create-project
create-project: ## Create a new project (PROJECT=name)
	@echo "Creating project $(PROJECT)..."
	@mkdir -p $(PROJECTS_DIR)/$(PROJECT)/src
	@mkdir -p $(PROJECTS_DIR)/$(PROJECT)/.cargo
	
	@# Create Cargo.toml
	@echo '[package]\nname = "$(PROJECT)"\nversion = "0.1.0"\nedition = "2021"\n\n[dependencies]\n\n[profile.dev]\npanic = "abort"\nopt-level = "s"\n\n[profile.release]\npanic = "abort"\nopt-level = "s"\nlto = true\ncodegen-units = 1' > $(PROJECTS_DIR)/$(PROJECT)/Cargo.toml
	
	@# Create .cargo/config.toml
	@echo '[build]\ntarget = "riscv32i-unknown-none-elf"\nrustflags = [\n  "-C", "link-arg=-Tmemory.x",\n  "-C", "link-arg=-Map=target/memory.map",\n  "-C", "link-arg=--gc-sections",\n  "-C", "linker=rust-lld",\n  "-C", "default-linker-libraries=no"\n]\n\n[unstable]\nbuild-std = ["core", "compiler_builtins"]\nbuild-std-features = ["compiler-builtins-mem"]\n\n[target.riscv32i-unknown-none-elf]\nrunner = "echo '\''Use simulator instead:'\'"' > $(PROJECTS_DIR)/$(PROJECT)/.cargo/config.toml
	
	@# Create memory.x
	@echo 'MEMORY\n{\n  /* RISC-V memory layout */\n  RAM : ORIGIN = 0x00000000, LENGTH = 64K\n}\n\nSECTIONS\n{\n  /* .text section containing code */\n  .text :\n  {\n    *(.text.entry)   /* Entry point */\n    *(.text*)        /* All other code sections */\n    . = ALIGN(4);\n  } > RAM\n\n  /* .rodata section containing constants */\n  .rodata :\n  {\n    *(.rodata*)      /* Read-only data */\n    . = ALIGN(4);\n  } > RAM\n\n  /* .data section containing initialized variables */\n  .data :\n  {\n    *(.data*)        /* Initialized data */\n    . = ALIGN(4);\n  } > RAM\n\n  /* .bss section containing uninitialized variables */\n  .bss (NOLOAD) :\n  {\n    _bss_start = .;\n    *(.bss*)         /* Uninitialized data */\n    *(COMMON)        /* Common block */\n    . = ALIGN(4);\n    _bss_end = .;\n  } > RAM\n\n  /* Stack grows downward from the end of RAM */\n  _stack_start = ORIGIN(RAM) + LENGTH(RAM);\n}' > $(PROJECTS_DIR)/$(PROJECT)/memory.x
	
	@# Create basic main.rs
	@echo '#![no_std]\n#![no_main]\n\nuse core::panic::PanicInfo;\n\n// UART base address - adjust based on your core configuration\nconst UART_TX_ADDR: usize = 0x02000000;\n\n#[panic_handler]\nfn panic(_info: &PanicInfo) -> ! {\n    loop {}\n}\n\n// Simple function to write to a memory-mapped register\nunsafe fn write_mmio(addr: usize, val: u8) {\n    core::ptr::write_volatile(addr as *mut u8, val);\n}\n\n// Write a byte to UART\nfn uart_putc(c: u8) {\n    unsafe {\n        write_mmio(UART_TX_ADDR, c);\n    }\n}\n\n// Write a string to UART\nfn uart_puts(s: &str) {\n    for c in s.bytes() {\n        uart_putc(c);\n    }\n}\n\n// Entry point\n#[no_mangle]\npub extern "C" fn _start() -> ! {\n    uart_puts("Hello, World from Rust on RISC-V!\\r\\n");\n    \n    // Loop forever\n    loop {}\n}' > $(PROJECTS_DIR)/$(PROJECT)/src/main.rs
	
	@# Create project.json
	@echo '{\n  "name": "$(PROJECT)",\n  "target": "riscv32i-unknown-none-elf",\n  "core": "picorv32",\n  "memory": {\n    "origin": "0x00000000",\n    "length": "64K"\n  },\n  "uart_base": "0x02000000"\n}' > $(PROJECTS_DIR)/$(PROJECT)/project.json
	
	@echo "Created project $(PROJECT) at $(PROJECTS_DIR)/$(PROJECT)"

.PHONY: list-projects
list-projects: ## List all projects
	$(PROJECT_MANAGER) list

.PHONY: project-info
project-info: ## Show project information (PROJECT=name)
	$(PROJECT_MANAGER) info $(PROJECT)

## Building
.PHONY: build
build: check-project ## Build a project (PROJECT=name, RELEASE=true/false)
	@echo "Building project $(PROJECT)..."
	@cd $(PROJECTS_DIR)/$(PROJECT) && . "$$HOME/.cargo/env" && \
	if [ "$(RELEASE)" = "true" ]; then \
		cargo build --release --target riscv32i-unknown-none-elf; \
	else \
		cargo build --target riscv32i-unknown-none-elf; \
	fi

.PHONY: build-all
build-all: ## Build all projects
	@for project in $$($(PROJECT_MANAGER) list | tail -n +2 | sed 's/^  - //'); do \
		echo "Building $$project..."; \
		cd $(PROJECTS_DIR)/$$project && . "$$HOME/.cargo/env" && \
		cargo build --release --target riscv32i-unknown-none-elf || echo "Failed to build $$project"; \
	done

## Simulation
.PHONY: simulate
simulate: check-project build ## Simulate a project (PROJECT=name, CORE=name)
	@echo "Running simulation: $(PROJECT) on $(CORE)"
	@mkdir -p $(OUTPUT_DIR)/$(PROJECT)
	@cd $(PROJECTS_DIR)/$(PROJECT) && . "$$HOME/.cargo/env" && \
	cargo objcopy --release -- -O binary $(PWD)/$(OUTPUT_DIR)/$(PROJECT)/$(PROJECT).bin
	@BINARY_PATH="$(PWD)/$(OUTPUT_DIR)/$(PROJECT)/$(PROJECT).bin"; \
	$(SIMULATOR) run $(CORE) "$$BINARY_PATH"

.PHONY: simulate-vcd
simulate-vcd: check-project build ## Simulate with VCD output (PROJECT=name, CORE=name)
	@echo "Running simulation with VCD: $(PROJECT) on $(CORE)"
	@mkdir -p $(OUTPUT_DIR)/$(PROJECT)
	@cd $(PROJECTS_DIR)/$(PROJECT) && . "$$HOME/.cargo/env" && \
	cargo objcopy --release -- -O binary $(PWD)/$(OUTPUT_DIR)/$(PROJECT)/$(PROJECT).bin
	@BINARY_PATH="$(PWD)/$(OUTPUT_DIR)/$(PROJECT)/$(PROJECT).bin"; \
	$(SIMULATOR) run $(CORE) "$$BINARY_PATH" --vcd

## Core management
.PHONY: list-cores
list-cores: ## List available cores
	$(SIMULATOR) list-cores

.PHONY: core-info
core-info: ## Show core information (CORE=name)
	$(SIMULATOR) core-info $(CORE)

## Utilities
.PHONY: convert-bin
convert-bin: ## Convert binary to hex (BIN=file.bin HEX=file.hex)
	@echo "Converting $(BIN) to $(HEX)..."
	@for objcopy in riscv64-unknown-elf-objcopy riscv32-unknown-elf-objcopy riscv-objcopy objcopy; do \
		if command -v $$objcopy >/dev/null 2>&1; then \
			$$objcopy -I binary -O verilog $(BIN) $(HEX) && exit 0; \
		fi; \
	done; \
	echo "Error: No objcopy tool found. Please install RISC-V GNU toolchain."; \
	exit 1

.PHONY: clean
clean: ## Clean build artifacts
	@echo "Cleaning build artifacts..."
	@rm -rf $(OUTPUT_DIR)/*
	@for project_dir in $(PROJECTS_DIR)/*/; do \
		if [ -f "$$project_dir/Cargo.toml" ]; then \
			echo "Cleaning $$project_dir"; \
			cd "$$project_dir" && cargo clean 2>/dev/null || true; \
			rm -f *.bin *.hex Cargo.lock 2>/dev/null || true; \
			cd - >/dev/null; \
		fi; \
	done
	@echo "Clean complete"

.PHONY: clean-all
clean-all: clean ## Clean everything including generated files
	@rm -f *.hex *.vcd *_sim
	@echo "Deep clean complete"

## Testing
.PHONY: run-test
run-test: check-project build ## Run tests for a project (PROJECT=name, CORE=name)
	@echo "Running test: $(PROJECT) on $(CORE)"
	@mkdir -p $(OUTPUT_DIR)/$(PROJECT)
	@cd $(PROJECTS_DIR)/$(PROJECT) && . "$$HOME/.cargo/env" && \
	cargo objcopy --release -- -O binary $(PWD)/$(OUTPUT_DIR)/$(PROJECT)/$(PROJECT).bin
	@BINARY_PATH="$(PWD)/$(OUTPUT_DIR)/$(PROJECT)/$(PROJECT).bin"; \
	$(SIMULATOR) run $(CORE) "$$BINARY_PATH" --test

.PHONY: test-hello-world
test-hello-world: ## Run the hello-world test
	@$(MAKE) run-test PROJECT=hello-world CORE=picorv32

.PHONY: test-all
test-all: ## Run tests for all projects on all cores
	@echo "Running all tests..."
	@for project in $$($(PROJECT_MANAGER) list | tail -n +2 | sed 's/^  - //'); do \
		for core in $$($(SIMULATOR) list-cores | tail -n +2 | sed 's/^  - //'); do \
			echo "=== Testing $$project on $$core ==="; \
			$(MAKE) run-test PROJECT=$$project CORE=$$core || echo "Test failed: $$project on $$core"; \
			echo; \
		done; \
	done
	@echo "All tests completed"

## Internal helpers
.PHONY: check-project
check-project:
	@if [ ! -d "$(PROJECTS_DIR)/$(PROJECT)" ]; then \
		echo "Error: Project $(PROJECT) not found"; \
		echo "Available projects:"; \
		$(PROJECT_MANAGER) list; \
		exit 1; \
	fi

.PHONY: check-core
check-core:
	@if ! $(SIMULATOR) list-cores | grep -q "$(CORE)"; then \
		echo "Error: Core $(CORE) not found"; \
		echo "Available cores:"; \
		$(SIMULATOR) list-cores; \
		exit 1; \
	fi

## Quick start examples
.PHONY: example
example: ## Run the hello-world example
	@echo "Running hello-world example..."
	@$(MAKE) simulate PROJECT=hello-world CORE=picorv32

# Include any additional makefiles
-include $(wildcard $(SCRIPTS_DIR)/*.mk)
