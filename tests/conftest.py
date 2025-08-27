"""
Pytest configuration for RISC-V Rust tests.
"""

import os
import sys
import pytest
from pathlib import Path

# Add the tools directory to the Python path
tools_dir = Path(__file__).parent.parent / "tools"
sys.path.append(str(tools_dir))

# Define fixtures for use in tests
@pytest.fixture
def workspace_root():
    """Return the workspace root directory."""
    return Path(__file__).parent.parent

@pytest.fixture
def regression_runner(workspace_root):
    """Return a regression runner instance."""
    from regression import RegressionRunner
    return RegressionRunner(workspace_root)
