# Regression Testing with pytest

This project includes a comprehensive pytest-based regression testing framework for validating RISC-V Rust projects on various cores.

## Setting Up

```bash
# Install all required Python dependencies
make setup-python
```

## Running Tests

```bash
# Run all regression tests
make regression

# Run regression tests for a specific project
make regression-project PROJECT=hello-world

# Run regression tests on a specific core
make regression-core CORE=picorv32

# Generate an XML report (for CI integration)
make regression-xml

# Run tests in parallel for faster execution
make regression-parallel
```

## Adding Tests

1. Create a `test_config.json` file in your project directory:
```json
{
  "tests": [
    {
      "description": "My Test",
      "cores": ["picorv32"],
      "expected_output": ["Expected string in output"],
      "timeout": 10000
    }
  ]
}
```

2. Run the tests with `make regression`

## Framework Features

- Automated test discovery and execution
- Test parameterization by project and core
- Parallel test execution for faster results
- Comprehensive reporting options (console, XML)
- Detailed test output with UART logging
- Customizable test configuration through JSON files

## Creating Custom Tests

For more advanced testing, you can create custom test functions in Python:

```python
# tests/test_custom.py
import pytest

def test_custom_verification(regression_runner):
    # Create a test configuration
    test_config = TestConfig(
        project_name="my-project",
        core_name="picorv32",
        expected_output=["Hello, World"],
        timeout=10000
    )
    
    # Run the test
    success, output, error = regression_runner.run_test(test_config)
    
    # Add custom verification logic
    assert success
    assert "Custom verification" in output
```
