#!/usr/bin/env python3
"""
Synthesis Tool using Yosys

Performs logic synthesis on Verilog RTL to generate a gate-level netlist.
"""

import os
import sys
import json
import subprocess
from pathlib import Path

def generate_synthesis_script(config, synthesis_dir):
    """Generate Yosys synthesis script"""
    
    script_content = f"""
# Yosys synthesis script for {config['core']}
# Generated automatically

# Read design files
"""
    
    for verilog_file in config["verilog_files"]:
        script_content += f"read_verilog {verilog_file}\n"
    
    script_content += f"""
# Set top module
hierarchy -check -top {config['top_module']}

# Generic synthesis
synth -top {config['top_module']}

# Technology mapping (generic for now)
abc -liberty /dev/null

# Write outputs
write_verilog {config['top_module']}_synth.v
write_json {config['top_module']}_synth.json

# Statistics
stat
"""
    
    script_file = synthesis_dir / "synthesis.ys"
    with open(script_file, 'w') as f:
        f.write(script_content)
    
    return script_file

def run_synthesis(core_name):
    """Run synthesis for the specified core"""
    
    # Project root
    project_root = Path(__file__).parent.parent.parent
    
    # Physical design directory
    physical_dir = project_root / "physical" / core_name
    if not physical_dir.exists():
        print(f"Error: Physical design not set up for core '{core_name}'")
        print(f"Run: make setup-physical CORE={core_name} PDK=<pdk_name>")
        return 1
    
    # Load configuration
    config_file = physical_dir / "config.json"
    if not config_file.exists():
        print(f"Error: Configuration file not found: {config_file}")
        return 1
    
    with open(config_file, 'r') as f:
        config = json.load(f)
    
    synthesis_dir = Path(config["synthesis"]["output_dir"])
    
    # Generate synthesis script
    script_file = generate_synthesis_script(config, synthesis_dir)
    print(f"Generated synthesis script: {script_file}")
    
    # Run Yosys
    try:
        print("Running Yosys synthesis...")
        result = subprocess.run([
            "yosys", 
            "-s", str(script_file)
        ], 
        cwd=synthesis_dir,
        capture_output=True, 
        text=True
        )
        
        # Write log files
        log_file = synthesis_dir / "synthesis.log"
        with open(log_file, 'w') as f:
            f.write("STDOUT:\n")
            f.write(result.stdout)
            f.write("\nSTDERR:\n")
            f.write(result.stderr)
        
        if result.returncode == 0:
            print("✅ Synthesis completed successfully")
            print(f"Outputs written to: {synthesis_dir}")
            print(f"Log file: {log_file}")
        else:
            print("❌ Synthesis failed")
            print(f"Check log file: {log_file}")
            return 1
            
    except FileNotFoundError:
        print("❌ Yosys not found")
        print("Make sure Yosys is installed and in your PATH")
        return 1
    except Exception as e:
        print(f"❌ Error running synthesis: {e}")
        return 1
    
    return 0

def main():
    if len(sys.argv) != 2:
        print("Usage: synthesize.py <core_name>")
        print("Example: synthesize.py picorv32")
        return 1
    
    core_name = sys.argv[1]
    return run_synthesis(core_name)

if __name__ == "__main__":
    sys.exit(main())
