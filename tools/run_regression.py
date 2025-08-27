#!/usr/bin/env python3
"""
Command-line interface for running RISC-V Rust regression tests.
"""

import sys
import argparse
import pytest
from pathlib import Path

def main():
    """Parse arguments and run tests."""
    parser = argparse.ArgumentParser(description="Run RISC-V Rust regression tests")
    
    # Test selection options
    parser.add_argument(
        "--project", 
        help="Run tests for a specific project"
    )
    parser.add_argument(
        "--core", 
        help="Run tests on a specific core"
    )
    
    # Output options
    parser.add_argument(
        "-v", "--verbose", 
        action="store_true", 
        help="Show verbose output"
    )
    
    args = parser.parse_args()
    
    # Base pytest arguments
    pytest_args = []
    
    # Add verbosity
    if args.verbose:
        pytest_args.append("-v")
    
    # Run tests from the tests directory
    test_dir = Path(__file__).parent.parent / "tests"
    pytest_args.append(str(test_dir))
    
    # Add project filter
    if args.project:
        pytest_args.append(f"--project={args.project}")
    
    # Add core filter
    if args.core:
        pytest_args.append(f"--core={args.core}")
    
    # Print header
    print("\n=== RISC-V Rust Regression Tests ===\n")
    print(f"Running tests with args: {' '.join(pytest_args)}\n")
    
    # Run pytest
    result = pytest.main(pytest_args)
    
    return result

if __name__ == "__main__":
    sys.exit(main())
