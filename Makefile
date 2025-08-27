# RISC-V Rust Development Environment
# ===================================

SHELL := /bin/bash
.DEFAULT_GOAL := help

# Directories
PROJECTS_DIR := projects
CORES_DIR := cores
TOOLS_DIR := tools
OUTPUT_DIR := output

# Python interpreter and virtual environment
PYTHON := python3
VENV_DIR := $(CURDIR)/.venv
VENV_PYTHON := $(VENV_DIR)/bin/python3

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

## Setup and initialization
.PHONY: setup-python
setup-python: ## Set up Python environment with uv
	@echo "Setting up Python environment..."
	@if ! command -v uv >/dev/null 2>&1; then \
		echo "Installing uv..."; \
		curl -LsSf https://astral.sh/uv/install.sh | sh; \
	fi
	@echo "Creating virtual environment at $(VENV_DIR)..."
	@uv venv -p $(PYTHON) $(VENV_DIR)
	@echo "Installing Python dependencies with uv..."
	@uv pip install --python $(VENV_PYTHON) -r requirements.txt
	@echo "Python setup complete!"

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
	elif command -v llvm-objcopy >/dev/null 2>&1; then \
		echo "✅ LLVM tools found"; \
	else \
		echo "❌ No RISC-V binary tools found"; \
		exit 1; \
	fi
	@if command -v uv >/dev/null 2>&1; then \
		echo "✅ uv package manager found"; \
	else \
		echo "❌ uv package manager not found"; \
		echo "   Install with: curl -LsSf https://astral.sh/uv/install.sh | sh"; \
		exit 1; \
	fi
	@if [ -d "$(VENV_DIR)" ] && [ -f "$(VENV_PYTHON)" ]; then \
		echo "✅ Python virtual environment found"; \
	else \
		echo "❌ Python virtual environment not found"; \
		echo "   Run: make setup-python"; \
		exit 1; \
	fi
	@if $(VENV_PYTHON) -c "import pytest" >/dev/null 2>&1; then \
		echo "✅ Python dependencies installed"; \
	else \
		echo "❌ Python dependencies missing"; \
		echo "   Run: make setup-python"; \
		exit 1; \
	fi
	@echo "✅ All dependencies found"

## Project management
.PHONY: list-projects
list-projects: ## List all projects
	$(PROJECT_MANAGER) list

.PHONY: project-info
project-info: ## Show project information (PROJECT=name)
	$(PROJECT_MANAGER) info $(PROJECT)

## Building
.PHONY: build
build: check-deps check-project ## Build a project (PROJECT=name)
	@echo "Building project $(PROJECT)..."
	@cd $(PROJECTS_DIR)/$(PROJECT) && . "$$HOME/.cargo/env" && \
	cargo build --release --target riscv32i-unknown-none-elf

## Simulation
.PHONY: simulate
simulate: check-deps check-project check-core build ## Simulate a project (PROJECT=name, CORE=name)
	@echo "Running simulation: $(PROJECT) on $(CORE)"
	@mkdir -p $(OUTPUT_DIR)/$(PROJECT)
	@cd $(PROJECTS_DIR)/$(PROJECT) && . "$$HOME/.cargo/env" && \
	cargo objcopy --release -- -O binary $(PWD)/$(OUTPUT_DIR)/$(PROJECT)/$(PROJECT).bin
	@BINARY_PATH="$(PWD)/$(OUTPUT_DIR)/$(PROJECT)/$(PROJECT).bin"; \
	$(SIMULATOR) run $(CORE) "$$BINARY_PATH"

## Core management
.PHONY: list-cores
list-cores: ## List available cores
	$(SIMULATOR) list-cores

.PHONY: core-info
core-info: ## Show core information (CORE=name)
	$(SIMULATOR) core-info $(CORE)

## Utilities
.PHONY: clean
clean: ## Clean build artifacts
	@echo "Cleaning build artifacts..."
	@rm -rf $(OUTPUT_DIR)/*
	@for project_dir in $(PROJECTS_DIR)/*/; do \
		if [ -f "$$project_dir/Cargo.toml" ]; then \
			echo "Cleaning $$project_dir"; \
			cd "$$project_dir" && cargo clean 2>/dev/null || true; \
		fi; \
	done
	@echo "Clean complete"

## Testing
.PHONY: regression
regression: check-deps ## Run regression tests
	@$(VENV_PYTHON) $(TOOLS_DIR)/run_regression.py -v

.PHONY: test-hello-world
test-hello-world: ## Run the hello-world test
	@$(MAKE) simulate PROJECT=hello-world CORE=picorv32

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

## Example
.PHONY: example
example: ## Run the hello-world example
	@echo "Running hello-world example..."
	@$(MAKE) simulate PROJECT=hello-world CORE=picorv32
