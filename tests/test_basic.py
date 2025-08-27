#!/usr/bin/env python3
"""
Basic test file for RISC-V Rust projects.
"""

import sys
import pytest
from pathlib import Path

# Add the tools directory to path
sys.path.append(str(Path(__file__).parent.parent))

# Import the regression runner
from tools.regression import TestConfig

def test_hello_world_on_picorv32(regression_runner):
    """Test the hello-world project on picorv32."""
    # Create a test configuration
    test_config = TestConfig(
        project_name="hello-world",
        core_name="picorv32",
        expected_output=["Hello, World from Rust on PicoRV32!"],
        timeout=10000
    )
    
    # Run the test
    success, output, error = regression_runner.run_test(test_config)
    
    # Print the output for debugging
    print("\nUART Output:")
    print("-" * 40)
    print(output)
    print("-" * 40)
    
    # Assert the test passed
    assert success, f"Test failed: {error}"

def test_project_discovery(regression_runner):
    """Test that projects are correctly discovered."""
    # Get the list of projects
    projects = regression_runner.list_projects()
    
    # Verify hello-world is in the list
    assert "hello-world" in projects, "hello-world project not found"
    
    # Print discovered projects
    print("\nDiscovered projects:")
    for project in projects:
        print(f"  - {project}")

def test_core_discovery(regression_runner):
    """Test that cores are correctly discovered."""
    # Get the list of cores
    cores = regression_runner.list_cores()
    
    # Verify picorv32 is in the list
    assert "picorv32" in cores, "picorv32 core not found"
    
    # Print discovered cores
    print("\nDiscovered cores:")
    for core in cores:
        print(f"  - {core}")

if __name__ == "__main__":
    # When run directly, run the tests
    pytest.main(["-xvs", __file__])
