#!/usr/bin/env python3
"""
Physical Design Setup Tool

Sets up the physical design environment for a given core and PDK.
"""

import os
import sys
import json
import shutil
from pathlib import Path

def setup_physical_design(core_name, pdk_name):
    """Set up physical design environment for a core with specified PDK"""
    
    # Project root
    project_root = Path(__file__).parent.parent.parent
    
    # Core directory
    core_dir = project_root / "cores" / core_name
    if not core_dir.exists():
        print(f"Error: Core '{core_name}' not found in cores directory")
        return 1
    
    # Load core configuration
    core_config_file = core_dir / "core.json"
    if not core_config_file.exists():
        print(f"Error: core.json not found for core '{core_name}'")
        return 1
    
    with open(core_config_file, 'r') as f:
        core_config = json.load(f)
    
    # Physical design output directory
    physical_dir = project_root / "physical" / core_name
    physical_dir.mkdir(parents=True, exist_ok=True)
    
    # Create synthesis directory
    synthesis_dir = physical_dir / "synthesis"
    synthesis_dir.mkdir(exist_ok=True)
    
    # Create place-and-route directory
    pnr_dir = physical_dir / "pnr"
    pnr_dir.mkdir(exist_ok=True)
    
    # Create signoff directory
    signoff_dir = physical_dir / "signoff"
    signoff_dir.mkdir(exist_ok=True)
    
    # Create physical design configuration
    # Filter out testbench files from synthesis
    synthesis_verilog_files = [f for f in core_config.get("verilog_files", [f"{core_name}.v"]) 
                              if not ("testbench" in f.lower() or "tb" in f.lower())]
    
    physical_config = {
        "core": core_name,
        "pdk": pdk_name,
        "top_module": core_config.get("top_module", core_name),
        "clock_frequency": core_config.get("clock_frequency", "100MHz"),
        "verilog_files": synthesis_verilog_files,
        "all_verilog_files": core_config.get("verilog_files", [f"{core_name}.v"]),  # Keep all files for reference
        "synthesis": {
            "tool": "yosys",
            "output_dir": str(synthesis_dir),
            "target_library": f"{pdk_name}_std_cell"
        },
        "pnr": {
            "tool": "openroad",
            "output_dir": str(pnr_dir),
            "floorplan": {
                "die_area": "0 0 500 500",
                "core_area": "10 10 490 490"
            }
        },
        "signoff": {
            "output_dir": str(signoff_dir),
            "checks": ["drc", "lvs", "antenna"]
        }
    }
    
    # Write physical design configuration
    config_file = physical_dir / "config.json"
    with open(config_file, 'w') as f:
        json.dump(physical_config, f, indent=2)
    
    # Copy Verilog files to synthesis directory
    for verilog_file in physical_config["all_verilog_files"]:
        src_file = core_dir / verilog_file
        if src_file.exists():
            dst_file = synthesis_dir / verilog_file
            shutil.copy2(src_file, dst_file)
            print(f"Copied {verilog_file} to synthesis directory")
        else:
            print(f"Warning: Verilog file {verilog_file} not found in core directory")
    
    print(f"Physical design setup complete for {core_name} with {pdk_name}")
    print(f"Configuration written to: {config_file}")
    
    return 0

def main():
    if len(sys.argv) != 3:
        print("Usage: setup.py <core_name> <pdk_name>")
        print("Example: setup.py picorv32 sky130")
        return 1
    
    core_name = sys.argv[1]
    pdk_name = sys.argv[2]
    
    return setup_physical_design(core_name, pdk_name)

if __name__ == "__main__":
    sys.exit(main())
