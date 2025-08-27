# Regression Testing Framework

This project includes a comprehensive pytest-based regression testing framework for validating RISC-V Rust projects across different cores and configurations.

## 🚀 Quick Start

```bash
# Using Nix (recommended)
nix develop --command make regression

# Traditional approach
make regression
```

## 🧪 Running Tests

### All Tests
```bash
# Run complete regression suite
make regression

# Run with verbose output
nix develop --command python3 tools/run_regression.py -v

# Run specific test
make test-hello-world
```

### Manual Test Execution
```bash
# Enter the environment
nix develop

# Run tests directly with pytest
python3 -m pytest tests/ -v

# Run with parallel execution
python3 -m pytest tests/ -n auto
```

## ⚙️ Test Configuration

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

### Configuration Options

- **`description`**: Human-readable test description
- **`cores`**: List of RISC-V cores to test against
- **`expected_output`**: Array of strings expected in UART output
- **`timeout`**: Maximum simulation time in cycles
- **`build_args`**: Optional additional build arguments

## 🔄 Test Process

The regression framework follows this workflow:

1. **Discovery**: Finds all projects with `test_config.json`
2. **Build**: Compiles Rust projects with RISC-V target
3. **Binary Conversion**: Uses `llvm-objcopy` to create simulation binaries
4. **Simulation**: Runs Icarus Verilog simulation with the specified core
5. **Output Capture**: Monitors UART output from the simulation
6. **Validation**: Compares actual output against expected patterns
7. **Reporting**: Generates detailed test results with debugging information

## 📊 Test Results

Test results include:

- ✅ **Pass/Fail status** for each test case
- 🖥️ **Complete UART output** for debugging
- ⏱️ **Execution timing** and performance metrics
- 🔧 **Build artifacts** and simulation files
- 📋 **Detailed error messages** for failures

### Example Output
```
====================================================== test session starts ======================================================
tests/test_basic.py::test_hello_world_on_picorv32 PASSED                                                              [ 33%]
tests/test_basic.py::test_project_discovery PASSED                                                                   [ 66%]
tests/test_basic.py::test_core_discovery PASSED                                                                      [100%]
======================================================= 3 passed in 1.11s =======================================================
```

## 🏗️ Adding New Tests

### 1. Create Project Structure
```
projects/my-project/
├── Cargo.toml
├── src/main.rs
└── test_config.json
```

### 2. Define Test Configuration
```json
{
  "tests": [
    {
      "description": "My Custom Test",
      "cores": ["picorv32"],
      "expected_output": ["Expected output string"],
      "timeout": 15000
    }
  ]
}
```

### 3. Run Tests
```bash
make regression
```

## 🔧 Test Environment

The testing framework uses the same Nix environment as development:

- **Python 3.13** with pytest framework
- **pytest-xdist** for parallel test execution
- **Rich** for beautiful console output
- **PyYAML** for configuration parsing
- All **RISC-V tools** and **simulation environment**

## 🐛 Debugging Failed Tests

### Verbose Output
```bash
# Run with maximum verbosity
nix develop --command python3 tools/run_regression.py -vv

# Run specific failing test
python3 -m pytest tests/test_basic.py::test_hello_world_on_picorv32 -v -s
```

### Check Build Artifacts
```bash
# Examine build outputs
ls output/

# Check simulation files
ls cores/picorv32/
```

### Manual Simulation
```bash
# Build manually
make build PROJECT=hello-world

# Run simulation manually
make simulate PROJECT=hello-world CORE=picorv32
```

## 🔄 Continuous Integration

The regression tests are designed to run in CI environments:

```yaml
# GitHub Actions example
- name: Run Regression Tests
  run: nix develop --command make regression
```

Benefits in CI:
- **Deterministic environment** via Nix
- **No external dependencies** to install
- **Fast execution** with proper caching
- **Comprehensive reporting** in CI logs

## 📈 Performance Considerations

- Tests run in **parallel** when possible using pytest-xdist
- **Simulation caching** reduces repeated builds
- **Nix store caching** speeds up environment setup
- **Incremental builds** only rebuild changed projects

## 🛠️ Extending the Framework

The testing framework is modular and extensible:

- **Add new cores**: Place core definitions in `cores/`
- **Custom assertions**: Extend `tools/regression.py`
- **New test types**: Add test cases in `tests/`
- **Output formats**: Modify reporting in `tools/run_regression.py`
