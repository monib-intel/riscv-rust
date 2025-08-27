#!/usr/bin/env python3
"""
Basic test script to run pytest on RISC-V projects.
"""

import os
import sys
import pytest
from pathlib import Path

def main():
    """Run regression tests using pytest."""
    # Get the path to the tools directory
    current_dir = Path(__file__).parent
    workspace_root = current_dir.parent
    
    # Add arguments to pass to pytest
    pytest_args = [
        # The path to the regression test module
        str(workspace_root / "tools" / "regression.py"),
        
        # Show verbose output
        "-v",
        
        # Disable warnings capture
        "-p", "no:warnings"
    ]
    
    # Add any command-line arguments
    pytest_args.extend(sys.argv[1:])
    
    # Run pytest
    exit_code = pytest.main(pytest_args)
    
    # Return the exit code
    return exit_code

if __name__ == "__main__":
    sys.exit(main())
