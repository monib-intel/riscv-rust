#!/usr/bin/env python3
"""
Project Manager for RISC-V Rust Projects
=========================================

Manages project creation, configuration, and build processes.
"""

import json
import shutil
import subprocess
from pathlib import Path
from typing import Dict, List, Optional, Any


class ProjectManager:
    """Manage RISC-V Rust projects."""
    
    def __init__(self, workspace_root: Path):
        """
        Initialize the project manager.
        
        Args:
            workspace_root: Root directory of the workspace
        """
        self.workspace_root = Path(workspace_root)
        self.projects_dir = self.workspace_root / "projects"
        self.cores_dir = self.workspace_root / "cores"
        self.tools_dir = self.workspace_root / "tools"
        
        # Ensure directories exist
        self.projects_dir.mkdir(exist_ok=True)
        self.cores_dir.mkdir(exist_ok=True)
    
    def list_projects(self) -> List[str]:
        """List all projects in the workspace."""
        if not self.projects_dir.exists():
            return []
        
        return [p.name for p in self.projects_dir.iterdir() 
                if p.is_dir() and (p / "Cargo.toml").exists()]
    
    def get_project_info(self, name: str) -> Dict[str, Any]:
        """Get information about a project."""
        project_path = self.projects_dir / name
        
        if not project_path.exists():
            raise ValueError(f"Project {name} not found")
        
        config_file = project_path / "project.json"
        if config_file.exists():
            return json.loads(config_file.read_text())
        
        # Fallback to basic info
        return {
            "name": name,
            "path": str(project_path),
            "has_cargo": (project_path / "Cargo.toml").exists()
        }
        
    def _get_cargo_template(self, name: str) -> str:
        """Get Cargo.toml template."""
        return f'''[package]
name = "{name}"
version = "0.1.0"
edition = "2021"

[dependencies]
# No external dependencies - bare-metal Rust only

[profile.dev]
panic = "abort"
opt-level = "s"

[profile.release]
panic = "abort"
opt-level = "s"
lto = true
codegen-units = 1
'''
    
    def _get_cargo_config_template(self) -> str:
        """Get .cargo/config.toml template."""
        return '''[build]
target = "riscv32i-unknown-none-elf"
rustflags = [
  "-C", "link-arg=-Tmemory.x",
  "-C", "link-arg=-Map=target/memory.map",
  "-C", "link-arg=--gc-sections",
  "-C", "linker=rust-lld",
  "-C", "default-linker-libraries=no"
]

[unstable]
build-std = ["core", "compiler_builtins"]
build-std-features = ["compiler-builtins-mem"]

[target.riscv32i-unknown-none-elf]
runner = "echo 'Use simulator instead:'"
'''
    
    def _get_memory_template(self) -> str:
        """Get memory.x template."""
        return '''MEMORY
{
  /* RISC-V memory layout */
  RAM : ORIGIN = 0x00000000, LENGTH = 64K
}

SECTIONS
{
  /* .text section containing code */
  .text :
  {
    *(.text.entry)   /* Entry point */
    *(.text*)        /* All other code sections */
    . = ALIGN(4);
  } > RAM

  /* .rodata section containing constants */
  .rodata :
  {
    *(.rodata*)      /* Read-only data */
    . = ALIGN(4);
  } > RAM

  /* .data section containing initialized variables */
  .data :
  {
    *(.data*)        /* Initialized data */
    . = ALIGN(4);
  } > RAM

  /* .bss section containing uninitialized variables */
  .bss (NOLOAD) :
  {
    _bss_start = .;
    *(.bss*)         /* Uninitialized data */
    *(COMMON)        /* Common block */
    . = ALIGN(4);
    _bss_end = .;
  } > RAM

  /* Stack grows downward from the end of RAM */
  _stack_start = ORIGIN(RAM) + LENGTH(RAM);
}
'''
    
    def _get_main_template(self, template: str) -> str:
        """Get main.rs template based on template type."""
        if template == "hello-world":
            return '''#![no_std]
#![no_main]

use core::panic::PanicInfo;

// UART base address - adjust based on your core configuration
const UART_TX_ADDR: usize = 0x02000000;

#[panic_handler]
fn panic(_info: &PanicInfo) -> ! {
    loop {}
}

// Simple function to write to a memory-mapped register
unsafe fn write_mmio(addr: usize, val: u8) {
    core::ptr::write_volatile(addr as *mut u8, val);
}

// Write a byte to UART
fn uart_putc(c: u8) {
    unsafe {
        write_mmio(UART_TX_ADDR, c);
    }
}

// Write a string to UART
fn uart_puts(s: &str) {
    for c in s.bytes() {
        uart_putc(c);
    }
}

// Entry point
#[no_mangle]
pub extern "C" fn _start() -> ! {
    uart_puts("Hello, World from Rust on RISC-V!\\r\\n");
    
    // Loop forever
    loop {}
}
'''
        else:
            # Minimal template
            return '''#![no_std]
#![no_main]

use core::panic::PanicInfo;

#[panic_handler]
fn panic(_info: &PanicInfo) -> ! {
    loop {}
}

#[no_mangle]
pub extern "C" fn _start() -> ! {
    // Your code here
    
    loop {}
}
'''


def main():
    """Command-line interface for project management."""
    import argparse
    
    parser = argparse.ArgumentParser(description="RISC-V Rust Project Manager")
    subparsers = parser.add_subparsers(dest="command", help="Available commands")
    
    # List projects command
    subparsers.add_parser("list", help="List all projects")
    
    # Info command
    info_parser = subparsers.add_parser("info", help="Show project information")
    info_parser.add_argument("name", help="Project name")
    
    # Get binary path command (to help with simulation)
    binary_path_parser = subparsers.add_parser("get-binary-path", help="Get path to a project binary")
    binary_path_parser.add_argument("name", help="Project name")
    binary_path_parser.add_argument("--debug", action="store_true", help="Use debug build instead of release")
    
    args = parser.parse_args()
    
    if not args.command:
        parser.print_help()
        return
    
    manager = ProjectManager(Path.cwd())
    
    try:
        if args.command == "list":
            projects = manager.list_projects()
            if projects:
                print("Projects:")
                for project in projects:
                    print(f"  - {project}")
            else:
                print("No projects found")
        
        elif args.command == "info":
            info = manager.get_project_info(args.name)
            print(f"Project: {info['name']}")
            for key, value in info.items():
                if key != "name":
                    print(f"  {key}: {value}")
        
        elif args.command == "get-binary-path":
            # Just return the expected path for the simulator to use
            project_path = manager.projects_dir / args.name
            target_dir = project_path / "target" / "riscv32i-unknown-none-elf"
            build_type = "debug" if args.debug else "release"
            
            # Try to figure out the binary name from Cargo.toml
            cargo_toml = project_path / "Cargo.toml"
            binary_name = args.name
            if cargo_toml.exists():
                import re
                content = cargo_toml.read_text()
                match = re.search(r'name\s*=\s*["\']([^"\']+)["\']', content)
                if match:
                    binary_name = match.group(1)
            
            binary_path = target_dir / build_type / binary_name
            print(binary_path)
    
    except Exception as e:
        print(f"Error: {e}")
        return 1


if __name__ == "__main__":
    exit(main() or 0)
