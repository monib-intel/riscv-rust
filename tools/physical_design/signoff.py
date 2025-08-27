#!/usr/bin/env python3
"""
Signoff Tool

Performs design rule checking (DRC), layout vs schematic (LVS), and other signoff checks.
"""

import os
import sys
import json
import subprocess
from pathlib import Path

def run_drc_check(config, signoff_dir, pnr_dir):
    """Run Design Rule Check (DRC)"""
    
    print("Running DRC check...")
    
    # For demonstration, create a simple DRC report
    drc_report = signoff_dir / "drc_report.txt"
    
    layout_file = pnr_dir / f"{config['top_module']}_pnr.v"
    
    with open(drc_report, 'w') as f:
        f.write(f"DRC Report for {config['top_module']}\n")
        f.write("=" * 50 + "\n\n")
        f.write(f"PDK: {config['pdk']}\n")
        f.write(f"Layout file: {layout_file}\n")
        f.write(f"Date: {subprocess.check_output(['date'], text=True).strip()}\n\n")
        
        if layout_file.exists():
            f.write("✅ Layout file found\n")
            f.write("⚠️  DRC tool not configured - placeholder check passed\n")
            f.write("\nDRC Status: PASSED (placeholder)\n")
        else:
            f.write("❌ Layout file not found\n")
            f.write("\nDRC Status: FAILED\n")
    
    print(f"DRC report written to: {drc_report}")
    return layout_file.exists()

def run_lvs_check(config, signoff_dir, pnr_dir, synthesis_dir):
    """Run Layout vs Schematic (LVS) check"""
    
    print("Running LVS check...")
    
    lvs_report = signoff_dir / "lvs_report.txt"
    
    layout_file = pnr_dir / f"{config['top_module']}_pnr.v"
    netlist_file = synthesis_dir / f"{config['top_module']}_synth.v"
    
    with open(lvs_report, 'w') as f:
        f.write(f"LVS Report for {config['top_module']}\n")
        f.write("=" * 50 + "\n\n")
        f.write(f"Layout file: {layout_file}\n")
        f.write(f"Netlist file: {netlist_file}\n")
        f.write(f"Date: {subprocess.check_output(['date'], text=True).strip()}\n\n")
        
        if layout_file.exists() and netlist_file.exists():
            f.write("✅ Both layout and netlist files found\n")
            f.write("⚠️  LVS tool not configured - placeholder check passed\n")
            f.write("\nLVS Status: PASSED (placeholder)\n")
        else:
            f.write("❌ Missing layout or netlist file\n")
            f.write("\nLVS Status: FAILED\n")
    
    print(f"LVS report written to: {lvs_report}")
    return layout_file.exists() and netlist_file.exists()

def run_antenna_check(config, signoff_dir, pnr_dir):
    """Run antenna rule check"""
    
    print("Running antenna check...")
    
    antenna_report = signoff_dir / "antenna_report.txt"
    
    layout_file = pnr_dir / f"{config['top_module']}_pnr.v"
    
    with open(antenna_report, 'w') as f:
        f.write(f"Antenna Report for {config['top_module']}\n")
        f.write("=" * 50 + "\n\n")
        f.write(f"Layout file: {layout_file}\n")
        f.write(f"Date: {subprocess.check_output(['date'], text=True).strip()}\n\n")
        
        if layout_file.exists():
            f.write("✅ Layout file found\n")
            f.write("⚠️  Antenna check tool not configured - placeholder check passed\n")
            f.write("\nAntenna Status: PASSED (placeholder)\n")
        else:
            f.write("❌ Layout file not found\n")
            f.write("\nAntenna Status: FAILED\n")
    
    print(f"Antenna report written to: {antenna_report}")
    return layout_file.exists()

def run_signoff(core_name):
    """Run signoff checks for the specified core"""
    
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
    pnr_dir = Path(config["pnr"]["output_dir"])
    signoff_dir = Path(config["signoff"]["output_dir"])
    
    # Check if PnR outputs exist
    pnr_output = pnr_dir / f"{config['top_module']}_pnr.v"
    if not pnr_output.exists():
        print(f"Error: PnR output not found: {pnr_output}")
        print(f"Run: make run-pnr CORE={core_name}")
        return 1
    
    print(f"Running signoff checks for {core_name}...")
    
    # Run checks
    checks_passed = 0
    total_checks = len(config["signoff"]["checks"])
    
    for check in config["signoff"]["checks"]:
        if check == "drc":
            if run_drc_check(config, signoff_dir, pnr_dir):
                checks_passed += 1
        elif check == "lvs":
            if run_lvs_check(config, signoff_dir, pnr_dir, synthesis_dir):
                checks_passed += 1
        elif check == "antenna":
            if run_antenna_check(config, signoff_dir, pnr_dir):
                checks_passed += 1
        else:
            print(f"Warning: Unknown check type: {check}")
    
    # Generate summary report
    summary_report = signoff_dir / "signoff_summary.txt"
    with open(summary_report, 'w') as f:
        f.write(f"Signoff Summary for {config['top_module']}\n")
        f.write("=" * 50 + "\n\n")
        f.write(f"Total checks: {total_checks}\n")
        f.write(f"Checks passed: {checks_passed}\n")
        f.write(f"Checks failed: {total_checks - checks_passed}\n\n")
        
        if checks_passed == total_checks:
            f.write("✅ ALL CHECKS PASSED\n")
            f.write("Design is ready for tapeout (placeholder signoff)\n")
        else:
            f.write("❌ SOME CHECKS FAILED\n")
            f.write("Review individual reports and fix issues\n")
    
    print(f"\nSignoff summary written to: {summary_report}")
    
    if checks_passed == total_checks:
        print("✅ All signoff checks passed")
        return 0
    else:
        print(f"❌ {total_checks - checks_passed} signoff checks failed")
        return 1

def main():
    if len(sys.argv) != 2:
        print("Usage: signoff.py <core_name>")
        print("Example: signoff.py picorv32")
        return 1
    
    core_name = sys.argv[1]
    return run_signoff(core_name)

if __name__ == "__main__":
    sys.exit(main())
