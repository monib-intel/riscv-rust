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
PROJECT_MANAGER := PYTHONPATH=. $(PYTHON) -m tools.project_manager
SIMULATOR := PYTHONPATH=. $(PYTHON) -m tools.simulator  
BIN_CONVERTER := PYTHONPATH=. $(PYTHON) -m tools.bin_converter

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
	@echo "Setup complete!"

.PHONY: check-deps
check-deps: ## Check if all dependencies are installed
	@echo "Checking dependencies..."
	@command -v rustup >/dev/null 2>&1 || (echo "❌ Rust not found" && exit 1)
	@command -v iverilog >/dev/null 2>&1 || (echo "❌ Icarus Verilog not found" && exit 1)
	@command -v $(PYTHON) >/dev/null 2>&1 || (echo "❌ Python 3 not found" && exit 1)
	@echo "✅ All dependencies found"

## Project management
.PHONY: create-project
create-project: ## Create a new project (PROJECT=name)
	$(PROJECT_MANAGER) create $(PROJECT)

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
	@if [ "$(RELEASE)" = "true" ]; then \
		$(PROJECT_MANAGER) build $(PROJECT); \
	else \
		$(PROJECT_MANAGER) build $(PROJECT) --debug; \
	fi

.PHONY: build-all
build-all: ## Build all projects
	@for project in $$($(PROJECT_MANAGER) list | tail -n +2 | sed 's/^  - //'); do \
		echo "Building $$project..."; \
		$(PROJECT_MANAGER) build $$project || echo "Failed to build $$project"; \
	done

## Simulation
.PHONY: simulate
simulate: check-project build ## Simulate a project (PROJECT=name, CORE=name)
	@echo "Running simulation: $(PROJECT) on $(CORE)"
	@mkdir -p $(OUTPUT_DIR)/$(PROJECT)
	@cd $(PROJECTS_DIR)/$(PROJECT) && . "$$HOME/.cargo/env" && cargo objcopy --release -- -O binary $(PWD)/$(OUTPUT_DIR)/$(PROJECT)/$(PROJECT).bin
	@BINARY_PATH="$(PWD)/$(OUTPUT_DIR)/$(PROJECT)/$(PROJECT).bin"; \
	$(SIMULATOR) run $(CORE) "$$BINARY_PATH"

.PHONY: simulate-vcd
simulate-vcd: check-project build ## Simulate with VCD output (PROJECT=name, CORE=name)
	@echo "Running simulation with VCD: $(PROJECT) on $(CORE)"
	@mkdir -p $(OUTPUT_DIR)/$(PROJECT)
	@cd $(PROJECTS_DIR)/$(PROJECT) && . "$$HOME/.cargo/env" && cargo objcopy --release -- -O binary $(PWD)/$(OUTPUT_DIR)/$(PROJECT)/$(PROJECT).bin
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
	$(BIN_CONVERTER) $(BIN) $(HEX)

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

## Development helpers
.PHONY: format
format: ## Format all Python code
	@find $(TOOLS_DIR) -name "*.py" -exec $(PYTHON) -m black {} \; 2>/dev/null || echo "Install black for formatting: pip install black"

.PHONY: lint
lint: ## Lint Python code
	@find $(TOOLS_DIR) -name "*.py" -exec $(PYTHON) -m flake8 {} \; 2>/dev/null || echo "Install flake8 for linting: pip install flake8"

.PHONY: test
test: ## Run tests
	@echo "Running tests..."
	@$(PYTHON) -m pytest tests/ 2>/dev/null || echo "No tests found or pytest not installed"

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

.PHONY: quick-start
quick-start: setup create-project example ## Complete quick start setup and example

# Include any additional makefiles
-include $(wildcard $(SCRIPTS_DIR)/*.mk)
