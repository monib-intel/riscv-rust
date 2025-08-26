#!/usr/bin/env python3
"""
Simulator Runner for RISC-V Cores
==================================

Manages simulation of RISC-V programs on various core implementations.
"""

import subprocess
import tempfile
from pathlib import Path
from typing import Dict, List, Optional, Any
import json


class SimulatorRunner:
    """Run simulations of RISC-V programs on various cores."""
    
    def __init__(self, workspace_root: Path):
        """
        Initialize the simulator runner.
        
        Args:
            workspace_root: Root directory of the workspace
        """
        self.workspace_root = Path(workspace_root)
        self.cores_dir = self.workspace_root / "cores"
        self.build_dir = self.workspace_root / "output" / "build"
        self.output_dir = self.workspace_root / "output"
        self.tools_dir = self.workspace_root / "tools"
        
        # Ensure directories exist
        self.build_dir.mkdir(parents=True, exist_ok=True)
    
    def list_cores(self) -> List[str]:
        """List available cores for simulation."""
        if not self.cores_dir.exists():
            return []
        
        cores = []
        for core_dir in self.cores_dir.iterdir():
            if core_dir.is_dir() and (core_dir / "core.json").exists():
                cores.append(core_dir.name)
        
        return cores
    
    def get_core_info(self, core_name: str) -> Dict[str, Any]:
        """Get information about a core."""
        core_dir = self.cores_dir / core_name
        config_file = core_dir / "core.json"
        
        if not config_file.exists():
            raise ValueError(f"Core {core_name} not found or missing core.json")
        
        return json.loads(config_file.read_text())
    
    def prepare_simulation(self, core_name: str, program_binary: Path, 
                          output_dir: Optional[Path] = None) -> Path:
        """
        Prepare simulation files for a given core and program.
        
        Args:
            core_name: Name of the core to simulate
            program_binary: Path to the program binary (ELF or raw binary)
            output_dir: Directory for simulation outputs (default: build/sim_<core>)
            
        Returns:
            Path to the simulation directory
        """
        if output_dir is None:
            output_dir = self.output_dir / f"sim_{core_name}"
        
        output_dir.mkdir(parents=True, exist_ok=True)
        
        core_info = self.get_core_info(core_name)
        core_dir = self.cores_dir / core_name
        
        # Convert binary to hex format
        hex_file = output_dir / "program.hex"
        temp_bin = output_dir / "program.bin"
        
        # Get memory size from core_info
        memory_size_str = core_info.get("memory", {}).get("size", "64K")
        if "K" in memory_size_str:
            memory_size = int(memory_size_str.replace("K", "")) * 1024
        else:
            memory_size = int(memory_size_str)
            
        # Get word size from core_info (default to 4 bytes for 32-bit)
        word_size = core_info.get("memory", {}).get("word_size", 4)
        memory_words = memory_size // word_size
        
        # Add extra words to match the testbench memory size (16384 words)
        memory_words = max(memory_words, 16384)
        
        # Print debug info
        print(f"Memory size: {memory_size} bytes, word size: {word_size} bytes, {memory_words} words")
        
        # Find the appropriate objcopy tool
        objcopy_tools = [
            "riscv64-unknown-elf-objcopy",
            "riscv32-unknown-elf-objcopy",
            "riscv-none-embed-objcopy",
            "riscv-none-elf-objcopy",
            "riscv-objcopy",
            "rust-objcopy",
            "llvm-objcopy"
        ]
        
        objcopy = None
        for tool in objcopy_tools:
            if subprocess.run(["which", tool], capture_output=True).returncode == 0:
                objcopy = tool
                break
        
        if not objcopy:
            print("⚠️ No RISC-V binary tools found. Install riscv-gnu-toolchain for better compatibility.")
            raise RuntimeError("Could not find objcopy tool. Please install RISC-V GNU toolchain.")
        
        print(f"Using {objcopy} for binary conversion")
        
        # First convert to raw binary if needed (for ELF files)
        if program_binary.suffix == '' and program_binary.stat().st_size > 1000:
            # Likely an ELF file, convert to raw binary first
            result = subprocess.run([
                objcopy, "-O", "binary", str(program_binary), str(temp_bin)
            ], capture_output=True, text=True)
            
            if result.returncode != 0:
                raise RuntimeError(f"Failed to convert ELF to binary: {result.stderr}")
                
            program_binary = temp_bin
        elif program_binary != temp_bin:
            # Copy the file to temp_bin
            import shutil
            shutil.copy(program_binary, temp_bin)
            program_binary = temp_bin
        
        # Pad the binary file with zeros to ensure it has enough words
        file_size = program_binary.stat().st_size
        required_size = memory_words * word_size
        
        if file_size < required_size:
            # Pad with zeros
            with open(program_binary, 'ab') as f:
                padding = b'\x00' * (required_size - file_size)
                f.write(padding)
            print(f"Padded binary: {file_size} bytes -> {required_size} bytes ({file_size // word_size} words -> {memory_words} words)")
        
        # We'll just use manual conversion to ensure Verilog compatibility
        print("Creating Verilog hex file manually...")
        
        # Manual conversion - create a properly formatted hex file for Verilog
        with open(program_binary, 'rb') as f:
            binary_data = f.read()
        
        # Get total number of words
        total_words = len(binary_data) // word_size
        if len(binary_data) % word_size != 0:
            total_words += 1
        
        # Pad to exactly memory_words
        if total_words < memory_words:
            binary_data = binary_data + b'\x00' * ((memory_words - total_words) * word_size)
        elif total_words > memory_words:
            # Trim to memory_words
            binary_data = binary_data[:memory_words * word_size]
            print(f"Warning: Binary too large, truncating to {memory_words} words")
        
        with open(hex_file, 'w') as f:
            # Format bytes into 32-bit words (4 bytes per word)
            for i in range(0, len(binary_data), word_size):
                # Extract up to 4 bytes (pad with zeros if needed)
                word_bytes = binary_data[i:i+word_size]
                if len(word_bytes) < word_size:
                    word_bytes = word_bytes + b'\x00' * (word_size - len(word_bytes))
                
                # Convert to 32-bit word value (little-endian by default)
                word_value = int.from_bytes(word_bytes, byteorder="little")
                
                # Write as hex value (8 digits, no 0x prefix)
                f.write(f"{word_value:08x}\n")
        
        print(f"Created Verilog hex file with exactly {memory_words} words")
        
        # Copy core files to simulation directory
        for verilog_file in core_info.get("verilog_files", []):
            src_file = core_dir / verilog_file
            dst_file = output_dir / verilog_file
            dst_file.parent.mkdir(parents=True, exist_ok=True)
            
            if src_file.exists():
                # Copy and potentially modify the file
                content = src_file.read_text()
                
                # Replace memory initialization if needed
                if "$readmemh" in content:
                    # Replace any readmemh calls to use our hex file
                    import re
                    content = re.sub(
                        r'\$readmemh\s*\(\s*"[^"]*"\s*,',
                        f'$readmemh("{hex_file.name}",',
                        content
                    )
                
                dst_file.write_text(content)
        
        return output_dir
    
    def run_simulation(self, core_name: str, program_binary: Path,
                      vcd_output: bool = False, timeout: int = 10000) -> Dict[str, Any]:
        """
        Run a simulation.
        
        Args:
            core_name: Name of the core to simulate
            program_binary: Path to the program binary
            vcd_output: Generate VCD waveform file
            timeout: Simulation timeout in cycles
            
        Returns:
            Dictionary with simulation results
        """
        # Prepare simulation
        sim_dir = self.prepare_simulation(core_name, program_binary)
        core_info = self.get_core_info(core_name)
        
        # Compile Verilog
        verilog_files = [sim_dir / f for f in core_info.get("verilog_files", [])]
        sim_executable = sim_dir / "simulation"
        
        compile_cmd = ["iverilog", "-g2012", "-o", str(sim_executable)]
        compile_cmd.extend(str(f) for f in verilog_files)
        
        compile_result = subprocess.run(
            compile_cmd,
            cwd=sim_dir,
            capture_output=True,
            text=True
        )
        
        if compile_result.returncode != 0:
            return {
                "success": False,
                "error": "Compilation failed",
                "stderr": compile_result.stderr,
                "stdout": compile_result.stdout
            }
        
        # Run simulation
        run_cmd = ["vvp", str(sim_executable)]
        if vcd_output:
            run_cmd.append("+vcd")
        
        run_result = subprocess.run(
            run_cmd,
            cwd=sim_dir,
            capture_output=True,
            text=True,
            timeout=timeout
        )
        
        # Check for test results
        test_result_file = sim_dir / "test_result.txt"
        uart_output_file = sim_dir / "uart_output.txt"
        
        test_status = "UNKNOWN"
        uart_output = ""
        
        if test_result_file.exists():
            test_status = test_result_file.read_text().strip()
        
        if uart_output_file.exists():
            uart_output = uart_output_file.read_text()
        
        # Format the output with test results and UART output
        formatted_output = run_result.stdout
        
        # Add a colorful test result
        if test_status == "PASS":
            formatted_output += f"\n\n✅ TEST PASSED\n"
        elif test_status == "FAIL":
            formatted_output += f"\n\n❌ TEST FAILED\n"
        
        # Add the UART output
        if uart_output:
            formatted_output += "\n--- UART Output ---\n"
            formatted_output += uart_output
            formatted_output += "\n------------------\n"
        
        result = {
            "success": run_result.returncode == 0,
            "returncode": run_result.returncode,
            "stdout": formatted_output,
            "stderr": run_result.stderr,
            "sim_dir": str(sim_dir),
            "test_status": test_status,
            "uart_output": uart_output
        }
        
        if vcd_output:
            vcd_file = sim_dir / "testbench.vcd"
            if vcd_file.exists():
                result["vcd_file"] = str(vcd_file)
        
        return result
    
    def create_core_config(self, name: str, verilog_files: List[str],
                          description: str = "") -> Path:
        """
        Create a core configuration file.
        
        Args:
            name: Core name
            verilog_files: List of Verilog files relative to core directory
            description: Core description
            
        Returns:
            Path to the created core directory
        """
        core_dir = self.cores_dir / name
        core_dir.mkdir(parents=True, exist_ok=True)
        
        config = {
            "name": name,
            "description": description,
            "verilog_files": verilog_files,
            "simulator": "iverilog",
            "memory": {
                "base_address": "0x00000000",
                "size": "64K"
            },
            "uart": {
                "base_address": "0x02000000"
            }
        }
        
        config_file = core_dir / "core.json"
        config_file.write_text(json.dumps(config, indent=2))
        
        return core_dir


def main():
    """Command-line interface for the simulator runner."""
    import argparse
    
    parser = argparse.ArgumentParser(description="RISC-V Simulator Runner")
    subparsers = parser.add_subparsers(dest="command", help="Available commands")
    
    # List cores command
    subparsers.add_parser("list-cores", help="List available cores")
    
    # Core info command
    info_parser = subparsers.add_parser("core-info", help="Show core information")
    info_parser.add_argument("core", help="Core name")
    
    # Run simulation command
    run_parser = subparsers.add_parser("run", help="Run simulation")
    run_parser.add_argument("core", help="Core name")
    run_parser.add_argument("binary", type=Path, help="Program binary")
    run_parser.add_argument("--vcd", action="store_true", help="Generate VCD output")
    run_parser.add_argument("--timeout", type=int, default=10000, help="Timeout in cycles")
    run_parser.add_argument("--test", action="store_true", help="Run in test mode with verification")
    
    args = parser.parse_args()
    
    if not args.command:
        parser.print_help()
        return
    
    runner = SimulatorRunner(Path.cwd())
    
    try:
        if args.command == "list-cores":
            cores = runner.list_cores()
            if cores:
                print("Available cores:")
                for core in cores:
                    print(f"  - {core}")
            else:
                print("No cores found")
        
        elif args.command == "core-info":
            info = runner.get_core_info(args.core)
            print(f"Core: {info['name']}")
            for key, value in info.items():
                if key != "name":
                    print(f"  {key}: {value}")
        
        elif args.command == "run":
            if not args.binary.exists():
                print(f"Error: Binary file {args.binary} not found")
                return 1
            
            result = runner.run_simulation(
                args.core, args.binary, args.vcd, args.timeout
            )
            
            if result["success"]:
                print("Simulation completed successfully")
                
                # Display test status if available
                if "test_status" in result:
                    if result["test_status"] == "PASS":
                        print("\n✅ TEST PASSED")
                    elif result["test_status"] == "FAIL":
                        print("\n❌ TEST FAILED")
                
                # Display UART output in a formatted way
                if "uart_output" in result and result["uart_output"].strip():
                    print("\n--- UART Output ---")
                    print(result["uart_output"])
                    print("------------------")
                
                # Display general simulation output
                print("\nSimulation Log:")
                print(result["stdout"])
                
                if "vcd_file" in result:
                    print(f"VCD file: {result['vcd_file']}")
            else:
                print("Simulation failed")
                print("Error:", result.get("error", "Unknown error"))
                if result["stderr"]:
                    print("stderr:", result["stderr"])
    
    except Exception as e:
        print(f"Error: {e}")
        return 1


if __name__ == "__main__":
    exit(main() or 0)
