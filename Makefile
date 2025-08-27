# RISC-V Rust Development Environment
# ===================================

SHELL := $(shell which bash)
.DEFAULT_GOAL := help

# Directories
PROJECTS_DIR := projects
CORES_DIR := cores
TOOLS_DIR := tools
OUTPUT_DIR := output

# Python interpreter (use system python which is provided by Nix)
PYTHON := python3

# Tools
PROJECT_MANAGER := $(PYTHON) $(TOOLS_DIR)/project_manager.py
SIMULATOR := $(PYTHON) $(TOOLS_DIR)/simulator.py

# Default values
PROJECT ?= hello-world
CORE ?= picorv32
RELEASE ?= true
PDK ?= sky130

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
	@echo "  PDK      - Process Design Kit (default: $(PDK))"

## Setup and initialization
.PHONY: setup-python
setup-python: ## [DEPRECATED] Python environment is now provided by Nix
	@echo "⚠️  This target is deprecated."
	@echo "   Python dependencies are now provided by the Nix environment."
	@echo "   Run 'nix develop' to activate the environment."

.PHONY: check-deps
check-deps: ## Check if all dependencies are installed
	@echo "Checking dependencies..."
	@command -v rustc >/dev/null 2>&1 || (echo "❌ Rust not found" && exit 1)
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
	@if $(PYTHON) -c "import pytest" >/dev/null 2>&1; then \
		echo "✅ Python dependencies installed"; \
	else \
		echo "❌ Python dependencies missing"; \
		echo "   Dependencies are provided by Nix environment"; \
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
	@cd $(PROJECTS_DIR)/$(PROJECT) && \
	cargo build --release --target riscv32i-unknown-none-elf

## Simulation
.PHONY: simulate
simulate: check-deps check-project check-core build ## Simulate a project (PROJECT=name, CORE=name)
	@echo "Running simulation: $(PROJECT) on $(CORE)"
	@mkdir -p $(OUTPUT_DIR)/$(PROJECT)
	@cd $(PROJECTS_DIR)/$(PROJECT) && \
	llvm-objcopy -O binary target/riscv32i-unknown-none-elf/release/picorv32-$(PROJECT) $(PWD)/$(OUTPUT_DIR)/$(PROJECT)/$(PROJECT).bin
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
	@rm -rf physical/
	@for project_dir in $(PROJECTS_DIR)/*/; do \
		if [ -f "$$project_dir/Cargo.toml" ]; then \
			echo "Cleaning $$project_dir"; \
			cd "$$project_dir" && cargo clean 2>/dev/null || true; \
		fi; \
	done
	@echo "Clean complete"

.PHONY: clean-physical
clean-physical: ## Clean only physical design artifacts
	@echo "Cleaning physical design artifacts..."
	@rm -rf $(OUTPUT_DIR)/physical/

## Physical Design (OpenROAD/OpenPDK)
.PHONY: check-physical-deps
check-physical-deps: ## Check physical design dependencies
	@echo "Checking physical design dependencies..."
	@command -v yosys >/dev/null 2>&1 || (echo "❌ Yosys not found" && exit 1)
	@command -v openroad >/dev/null 2>&1 || (echo "❌ OpenROAD not found" && exit 1)
	@command -v klayout >/dev/null 2>&1 || (echo "⚠️  KLayout not found (optional)" && true)
	@echo "✅ Physical design tools found"

.PHONY: setup-physical
setup-physical: check-core ## Set up physical design for a core (CORE=name, PDK=name)
	@echo "Setting up physical design for core $(CORE) with PDK $(PDK)..."
	@mkdir -p physical/$(CORE)
	@$(PYTHON) $(TOOLS_DIR)/physical_design/setup.py $(CORE) $(PDK)

.PHONY: run-synthesis
run-synthesis: check-core ## Run synthesis (CORE=name)
	@echo "Running synthesis for core $(CORE)..."
	@$(PYTHON) $(TOOLS_DIR)/physical_design/synthesize.py $(CORE)

.PHONY: run-pnr
run-pnr: check-core ## Run place-and-route (CORE=name)
	@echo "Running place-and-route for core $(CORE)..."
	@$(PYTHON) $(TOOLS_DIR)/physical_design/pnr.py $(CORE)

.PHONY: run-signoff
run-signoff: check-core ## Run signoff (CORE=name)
	@echo "Running signoff for core $(CORE)..."
	@$(PYTHON) $(TOOLS_DIR)/physical_design/signoff.py $(CORE)

.PHONY: run-physical-flow
run-physical-flow: check-core ## Run full physical design flow (CORE=name, PDK=name)
	@echo "Running full physical design flow for core $(CORE) with PDK $(PDK)..."
	@$(MAKE) setup-physical CORE=$(CORE) PDK=$(PDK)
	@$(MAKE) run-synthesis CORE=$(CORE)
	@$(MAKE) run-pnr CORE=$(CORE)
	@$(MAKE) run-signoff CORE=$(CORE)
	@echo "✅ Physical design flow complete"

## Testing
.PHONY: regression
regression: check-deps ## Run regression tests
	@$(PYTHON) $(TOOLS_DIR)/run_regression.py -v

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
