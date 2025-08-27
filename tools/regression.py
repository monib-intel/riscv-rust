#!/usr/bin/env python3
"""
RISC-V Rust Regression Test Framework
====================================

A pytest-based framework for automating regression tests of RISC-V Rust projects
across multiple cores.
"""

import os
import json
import pytest
import subprocess
from pathlib import Path
from typing import Dict, List, Optional, Any, Tuple
from dataclasses import dataclass


@dataclass
class TestConfig:
    """Configuration for a single test."""
    project_name: str
    core_name: str
    expected_output: List[str]  # List of strings that should appear in UART output
    timeout: int = 10000  # Simulation timeout in cycles


# Mark the TestConfig class to be excluded from test collection
TestConfig.__test__ = False


class RegressionRunner:
    """Run regression tests for RISC-V Rust projects."""
    
    def __init__(self, workspace_root: Path):
        """
        Initialize the regression test runner.
        
        Args:
            workspace_root: Root directory of the workspace
        """
        self.workspace_root = Path(workspace_root)
        self.projects_dir = self.workspace_root / "projects"
        self.cores_dir = self.workspace_root / "cores"
        self.output_dir = self.workspace_root / "output"
        self.tools_dir = self.workspace_root / "tools"
        
        # Ensure output directory exists
        self.output_dir.mkdir(parents=True, exist_ok=True)
    
    def list_projects(self) -> List[str]:
        """List all projects in the workspace."""
        if not self.projects_dir.exists():
            return []
        
        return [p.name for p in self.projects_dir.iterdir() 
                if p.is_dir() and (p / "Cargo.toml").exists()]
                
    def list_cores(self) -> List[str]:
        """List available cores for simulation."""
        if not self.cores_dir.exists():
            return []
        
        cores = []
        for core_dir in self.cores_dir.iterdir():
            if core_dir.is_dir() and (core_dir / "core.json").exists():
                cores.append(core_dir.name)
        
        return cores
    
    def discover_tests(self) -> List[TestConfig]:
        """Discover available tests from test configuration files."""
        tests = []
        
        # Look for test_config.json files in project directories
        for project_dir in self.projects_dir.iterdir():
            if not project_dir.is_dir():
                continue
                
            test_config = project_dir / "test_config.json"
            if test_config.exists():
                try:
                    config = json.loads(test_config.read_text())
                    
                    # Process each test configuration
                    for test in config.get("tests", []):
                        cores = test.get("cores", ["picorv32"])  # Default to picorv32
                        
                        # Create a test for each core
                        for core in cores:
                            tests.append(TestConfig(
                                project_name=project_dir.name,
                                core_name=core,
                                expected_output=test.get("expected_output", []),
                                timeout=test.get("timeout", 10000)
                            ))
                except Exception as e:
                    print(f"Error loading test config from {test_config}: {e}")
        
        return tests
    
    def run_test(self, test_config: TestConfig) -> Tuple[bool, str, str]:
        """
        Run a single test based on its configuration.
        
        Args:
            test_config: Configuration for the test to run
            
        Returns:
            Tuple of (success, output, error_message)
        """
        print(f"Running test: {test_config.project_name} on {test_config.core_name}")
        
        # Build the project
        build_success, build_output = self._build_project(test_config.project_name)
        if not build_success:
            return False, "", f"Build failed: {build_output}"
        
        # Run simulation
        sim_success, sim_output, uart_output = self._run_simulation(
            test_config.project_name, 
            test_config.core_name
        )
        
        if not sim_success:
            return False, uart_output, f"Simulation failed: {sim_output}"
        
        # Verify output contains expected strings
        for expected in test_config.expected_output:
            if expected not in uart_output:
                return False, uart_output, f"Expected output not found: '{expected}'"
        
        return True, uart_output, ""
    
    def _build_project(self, project_name: str) -> Tuple[bool, str]:
        """
        Build a project using cargo.
        
        Args:
            project_name: Name of the project to build
            
        Returns:
            Tuple of (success, output)
        """
        project_path = self.projects_dir / project_name
        
        # Run cargo build
        cmd = [
            "cargo", "build", 
            "--release", 
            "--target", "riscv32i-unknown-none-elf"
        ]
        
        result = subprocess.run(
            cmd,
            cwd=project_path,
            capture_output=True,
            text=True
        )
        
        return result.returncode == 0, result.stdout + "\n" + result.stderr
    
    def _run_simulation(self, project_name: str, core_name: str) -> Tuple[bool, str, str]:
        """
        Run simulation for a project on a core.
        
        Args:
            project_name: Name of the project to simulate
            core_name: Name of the core to simulate on
            
        Returns:
            Tuple of (success, simulator_output, uart_output)
        """
        # Create output directory
        output_dir = self.output_dir / f"{project_name}"
        output_dir.mkdir(parents=True, exist_ok=True)
        
        # Generate binary from ELF
        project_path = self.projects_dir / project_name
        binary_path = output_dir / f"{project_name}.bin"
        
        objcopy_cmd = [
            "cargo", "objcopy", 
            "--release", 
            "--", 
            "-O", "binary", 
            str(binary_path)
        ]
        
        result = subprocess.run(
            objcopy_cmd,
            cwd=project_path,
            capture_output=True,
            text=True
        )
        
        if result.returncode != 0:
            return False, f"Binary conversion failed: {result.stderr}", ""
        
        # Run simulation
        simulator_script = self.tools_dir / "simulator.py"
        
        sim_cmd = [
            "python3", 
            str(simulator_script), 
            "run", 
            core_name, 
            str(binary_path)
        ]
        
        result = subprocess.run(
            sim_cmd,
            capture_output=True,
            text=True
        )
        
        # Get UART output
        uart_output = ""
        uart_file = self.output_dir / f"sim_{core_name}" / "uart_output.txt"
        
        if uart_file.exists():
            uart_output = uart_file.read_text()
        
        return result.returncode == 0, result.stdout + "\n" + result.stderr, uart_output


# Pytest integration functions

def pytest_addoption(parser):
    """Add command-line options for the regression tests."""
    parser.addoption(
        "--project", 
        action="store", 
        default=None, 
        help="Run tests for a specific project"
    )
    parser.addoption(
        "--core", 
        action="store", 
        default=None, 
        help="Run tests on a specific core"
    )


def pytest_generate_tests(metafunc):
    """Generate test cases based on discovered tests."""
    if "test_config" in metafunc.fixturenames:
        # Create the regression runner
        workspace_root = Path(__file__).parent.parent
        runner = RegressionRunner(workspace_root)
        
        # Discover tests
        all_tests = runner.discover_tests()
        
        # Filter tests based on command-line options
        project_filter = metafunc.config.getoption("project")
        core_filter = metafunc.config.getoption("core")
        
        filtered_tests = []
        for test in all_tests:
            if project_filter and test.project_name != project_filter:
                continue
            if core_filter and test.core_name != core_filter:
                continue
            filtered_tests.append(test)
        
        # Create IDs for the tests
        ids = [f"{test.project_name}_{test.core_name}" for test in filtered_tests]
        
        metafunc.parametrize("test_config", filtered_tests, ids=ids)


# The actual test function
def test_risc_v_project(test_config):
    """Run a RISC-V Rust project test."""
    workspace_root = Path(__file__).parent.parent
    runner = RegressionRunner(workspace_root)
    
    success, output, error = runner.run_test(test_config)
    
    # Add the output to the test report
    if output:
        print("\nUART Output:")
        print("-" * 40)
        print(output)
        print("-" * 40)
    
    assert success, f"Test failed: {error}"


if __name__ == "__main__":
    # When run directly, discover and print available tests
    workspace_root = Path(__file__).parent.parent
    runner = RegressionRunner(workspace_root)
    
    tests = runner.discover_tests()
    
    print(f"Discovered {len(tests)} tests:")
    for test in tests:
        print(f"  - {test.project_name} on {test.core_name}")
        print(f"    Expected output: {test.expected_output}")
        print(f"    Timeout: {test.timeout} cycles")
        print()
