# Physical Design Integration Guide

This document describes how to use the physical design tools integrated into the RISC-V Rust development environment.

## Overview

The physical design flow transforms synthesizable RTL (Verilog) into physical layouts ready for fabrication. This environment integrates:

- **Yosys**: Open-source synthesis tool
- **OpenROAD**: Open-source place-and-route tool
- **KLayout**: Layout viewer (optional)
- **PDK Support**: Sky130, GF180MCU, and other open PDKs

## Prerequisites

### Required Tools

On Ubuntu 22.04, install the required tools:

```bash
# Install Yosys

# Install KLayout (optional)

# Install OpenROAD dependencies

# Build and install OpenROAD

# Verify installations


```
## Flow Script

https://github.com/The-OpenROAD-Project/OpenROAD-flow-scripts

## Supported PDKs

- **sky130**: SkyWater 130nm open PDK
- **gf180mcu**: GlobalFoundries 180nm MCU PDK
- **asap7**: Academic 7nm FinFET PDK

## Quick Start

### 1. Set Up Physical Design Environment

```bash
# Set up physical design for a core with Sky130 PDK
make setup-physical CORE=picorv32 PDK=sky130
```

This creates:
- `physical/<pdk>/picorv32/` directory structure
- Configuration file with design parameters
- Copies Verilog files to synthesis directory

### 2. Run Synthesis

```bash
# Synthesize the RTL to gate-level netlist
make run-synthesis CORE=picorv32
```

Outputs:
- `output/<pdk>/physical/picorv32/synthesis/picorv32_synth.v` - Gate-level netlist
- `output/<pdk>/physical/picorv32/synthesis/picorv32_synth.json` - JSON representation
- `output/<pdk>/physical/picorv32/synthesis/synthesis.log` - Synthesis log

### 3. Run Place-and-Route

```bash
# Place and route the synthesized netlist
make run-pnr CORE=picorv32
```

Outputs:
- `output/<pdk>/physical/picorv32/pnr/picorv32_pnr.v` - Placed and routed netlist
- `output/<pdk>/physical/picorv32/pnr/picorv32_placed.def` - DEF layout file
- `output/<pdk>/physical/picorv32/pnr/pnr.log` - PnR log

### 4. Run Signoff Checks

```bash
# Run DRC, LVS, and antenna checks
make run-signoff CORE=picorv32
```

Outputs:
- `output/<pdk>/physical/picorv32/signoff/drc_report.txt` - Design rule check
- `output/<pdk>/physical/picorv32/signoff/lvs_report.txt` - Layout vs schematic
- `output/<pdk>/physical/picorv32/signoff/antenna_report.txt` - Antenna rule check
- `output/<pdk>/physical/picorv32/signoff/signoff_summary.txt` - Overall summary

### 5. Complete Flow

```bash
# Run the entire physical design flow
make run-physical-flow CORE=picorv32 PDK=sky130
```

## Directory Structure

After setup, the physical design directory structure looks like:

```
output/
└── physical/
  └── <pdk>/
      └── picorv32/
          ├── config.json              # Physical design configuration
          ├── synthesis/
          │   ├── picorv32.v           # RTL source (copied)
          │   ├── picorv32_synth.v     # Synthesized netlist
          │   ├── picorv32_synth.json  # JSON netlist
          │   ├── synthesis.ys         # Yosys script
          │   └── synthesis.log        # Synthesis log
          ├── pnr/
          │   ├── picorv32_pnr.v       # Placed and routed netlist
          │   ├── picorv32_placed.def  # DEF layout
          │   ├── pnr.tcl              # OpenROAD script
          │   └── pnr.log              # PnR log
          └── signoff/
              ├── drc_report.txt       # DRC results
              ├── lvs_report.txt       # LVS results
              ├── antenna_report.txt   # Antenna check results
              └── signoff_summary.txt  # Summary report
```

## Configuration

The `config.json` file controls physical design parameters:

```json
{
  "core": "picorv32",
  "pdk": "sky130",
  "top_module": "picorv32",
  "clock_frequency": "100MHz",
  "verilog_files": ["picorv32.v"],
  "synthesis": {
    "tool": "yosys",
    "output_dir": "physical/picorv32/synthesis",
    "target_library": "sky130_std_cell"
  },
  "pnr": {
    "tool": "openroad",
    "output_dir": "physical/picorv32/pnr",
    "floorplan": {
      "die_area": "0 0 500 500",
      "core_area": "10 10 490 490"
    }
  },
  "signoff": {
    "output_dir": "physical/picorv32/signoff",
    "checks": ["drc", "lvs", "antenna"]
  }
}
```

## Advanced Usage

### Custom Constraints

Create timing constraints in your project directory:

```bash
# Create SDC file for timing constraints
echo "create_clock -name clk -period 10 [get_ports clk]" > projects/my-project/constraints.sdc
```

### Custom Floorplan

Modify the floorplan in `config.json`:

```json
"floorplan": {
  "die_area": "0 0 1000 1000",
  "core_area": "50 50 950 950",
  "aspect_ratio": 1.0,
  "utilization": 0.7
}
```

### Adding Custom Libraries

For proprietary PDKs, add library paths:

```json
"synthesis": {
  "tool": "yosys",
  "liberty_files": ["/path/to/library.lib"],
  "lef_files": ["/path/to/cells.lef"]
}
```

## Troubleshooting

### Common Issues

1. **Tools not found**
   ```bash
   # Check tool availability
   make check-physical-deps
   
   # Enter Nix environment
   nix develop
   ```

2. **Synthesis fails**
   ```bash
   # Check synthesis log
   cat physical/picorv32/synthesis/synthesis.log
   
   # Verify Verilog syntax
   iverilog -t null cores/picorv32/picorv32.v
   ```

3. **PnR fails**
   ```bash
   # Check PnR log
   cat physical/picorv32/pnr/pnr.log
   
   # Verify synthesized netlist
   cat physical/picorv32/synthesis/picorv32_synth.v
   ```

### Debug Mode

Enable verbose output for debugging:

```bash
# Run with verbose output
VERBOSE=1 make run-synthesis CORE=picorv32
```

## Integration with CI/CD

Example GitHub Actions workflow:

```yaml
```

## Future Enhancements

- [ ] Full PDK integration with timing models
- [ ] Power analysis integration
- [ ] Multi-corner analysis
- [ ] DFT (Design for Test) insertion
- [ ] Formal verification integration
- [ ] Layout visualization in web interface

## References

- [Yosys Documentation](https://yosyshq.net/yosys/)
- [OpenROAD Documentation](https://openroad.readthedocs.io/)
- [SkyWater PDK](https://skywater-pdk.readthedocs.io/)
- [OpenLane Flow](https://openlane.readthedocs.io/)
