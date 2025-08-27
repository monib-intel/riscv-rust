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
        self.output_dir = self.workspace_root / "output"
        
        # Ensure directories exist
        self.output_dir.mkdir(parents=True, exist_ok=True)
    
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
    
    def prepare_simulation(self, core_name: str, program_binary: Path) -> Path:
        """
        Prepare simulation files for a given core and program.
        
        Args:
            core_name: Name of the core to simulate
            program_binary: Path to the program binary (ELF or raw binary)
            
        Returns:
            Path to the simulation directory
        """
        output_dir = self.output_dir / f"sim_{core_name}"
        output_dir.mkdir(parents=True, exist_ok=True)
        
        core_info = self.get_core_info(core_name)
        core_dir = self.cores_dir / core_name
        
        # Convert binary to hex format
        hex_file = output_dir / "program.hex"
        
        # Copy the binary file to the simulation directory
        import shutil
        shutil.copy(program_binary, output_dir / "program.bin")
        
        # Create a hex file manually from the binary data
        with open(program_binary, 'rb') as bin_file, open(hex_file, 'w') as hex_file_out:
            # Read the binary data
            bin_data = bin_file.read()
            
            # Convert to hex, 4 bytes (32 bits) at a time
            for i in range(0, len(bin_data), 4):
                # Get 4 bytes, pad with zeros if needed
                chunk = bin_data[i:i+4].ljust(4, b'\0')
                
                # Convert to 32-bit integer (little endian)
                value = int.from_bytes(chunk, byteorder='little')
                
                # Write as hex
                hex_file_out.write(f"{value:08x}\n")
        
        # Copy core files to simulation directory
        for verilog_file in core_info.get("verilog_files", []):
            src_file = core_dir / verilog_file
            dst_file = output_dir / verilog_file
            dst_file.parent.mkdir(parents=True, exist_ok=True)
            
            if src_file.exists():
                # Copy the file
                import shutil
                shutil.copy(src_file, dst_file)
        
        return output_dir
    
    def run_simulation(self, core_name: str, program_binary: Path,
                      vcd_output: bool = False) -> Dict[str, Any]:
        """
        Run a simulation.
        
        Args:
            core_name: Name of the core to simulate
            program_binary: Path to the program binary
            vcd_output: Generate VCD waveform file
            
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
            text=True
        )
        
        # Check for UART output
        uart_output_file = sim_dir / "uart_output.txt"
        uart_output = ""
        
        if uart_output_file.exists():
            uart_output = uart_output_file.read_text()
        
        result = {
            "success": run_result.returncode == 0,
            "returncode": run_result.returncode,
            "stdout": run_result.stdout,
            "stderr": run_result.stderr,
            "sim_dir": str(sim_dir),
            "uart_output": uart_output
        }
        
        if vcd_output:
            vcd_file = sim_dir / "testbench.vcd"
            if vcd_file.exists():
                result["vcd_file"] = str(vcd_file)
        
        return result


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
                args.core, args.binary, args.vcd
            )
            
            if result["success"]:
                print("Simulation completed successfully")
                
                # Display UART output in a formatted way
                if "uart_output" in result and result["uart_output"].strip():
                    print("\n--- UART Output ---")
                    print(result["uart_output"])
                    print("------------------")
                
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
