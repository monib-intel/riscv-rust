# Regression Testing

This project includes a pytest-based regression testing framework for validating RISC-V Rust projects.

## Running Tests

```bash
# Set up Python environment
make setup-python

# Run all regression tests
make regression
```

## Test Configuration

Each project can include a `test_config.json` file that defines test expectations:

```json
{
  "tests": [
    {
      "description": "Hello World Test",
      "cores": ["picorv32"],
      "expected_output": ["Hello, World from Rust on PicoRV32!"],
      "timeout": 10000
    }
  ]
}
```

## Test Process

The regression framework:

1. Builds the Rust project
2. Converts the binary to a format for simulation
3. Runs the simulation using Icarus Verilog
4. Captures UART output
5. Verifies output against expected strings

## Test Results

Test results are displayed in the console with UART output for debugging.
