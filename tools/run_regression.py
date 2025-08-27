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
    parser.add_argument(
        "--test", 
        help="Run a specific test by name"
    )
    
    # Output options
    parser.add_argument(
        "-v", "--verbose", 
        action="store_true", 
        help="Show verbose output"
    )
    parser.add_argument(
        "--no-header", 
        action="store_true", 
        help="Don't show header with test information"
    )
    parser.add_argument(
        "--junit-xml", 
        help="Generate JUnit XML report"
    )
    
    # Additional pytest arguments
    parser.add_argument(
        "--pytest-args",
        help="Additional arguments to pass to pytest (as a single string)"
    )
    parser.add_argument(
        "remaining_args", 
        nargs="*", 
        help="Additional positional arguments to pass to pytest"
    )
    
    args = parser.parse_args()
    
    # Base pytest arguments
    pytest_args = []
    
    # Add verbosity
    if args.verbose:
        pytest_args.append("-v")
    
    # Add test selection
    if args.test:
        pytest_args.append(args.test)
    else:
        # Run all tests by default
        test_dir = Path(__file__).parent.parent / "tests"
        pytest_args.append(str(test_dir))
    
    # Add project filter
    if args.project:
        pytest_args.append(f"--project={args.project}")
    
    # Add core filter
    if args.core:
        pytest_args.append(f"--core={args.core}")
    
    # Add JUnit XML report
    if args.junit_xml:
        pytest_args.append(f"--junitxml={args.junit_xml}")
    
    # Add additional arguments from --pytest-args
    if args.pytest_args:
        # Split the string on spaces but respect quoted arguments
        import shlex
        pytest_args.extend(shlex.split(args.pytest_args))
    
    # Add remaining positional arguments
    pytest_args.extend(args.remaining_args)
    
    # Print header
    if not args.no_header:
        print("\n=== RISC-V Rust Regression Tests ===\n")
        print(f"Running tests with args: {' '.join(pytest_args)}\n")
    
    # Run pytest
    result = pytest.main(pytest_args)
    
    return result

if __name__ == "__main__":
    sys.exit(main())
