#!/usr/bin/env python3
"""
Project Manager for RISC-V Rust Projects
=========================================

Manages project creation, configuration, and build processes.
"""

import json
import subprocess
from pathlib import Path
from typing import Dict, List, Any


class ProjectManager:
    """Manage RISC-V Rust projects."""
    
    def __init__(self, workspace_root: Path):
        """
        Initialize the project manager.
        
        Args:
            workspace_root: Root directory of the workspace
        """
        self.workspace_root = Path(workspace_root)
        self.projects_dir = self.workspace_root / "projects"
    
    def list_projects(self) -> List[str]:
        """List all projects in the workspace."""
        if not self.projects_dir.exists():
            return []
        
        return [p.name for p in self.projects_dir.iterdir() 
                if p.is_dir() and (p / "Cargo.toml").exists()]
    
    def get_project_info(self, name: str) -> Dict[str, Any]:
        """Get information about a project."""
        project_path = self.projects_dir / name
        
        if not project_path.exists():
            raise ValueError(f"Project {name} not found")
        
        config_file = project_path / "project.json"
        if config_file.exists():
            return json.loads(config_file.read_text())
        
        # Fallback to basic info
        return {
            "name": name,
            "path": str(project_path),
            "has_cargo": (project_path / "Cargo.toml").exists()
        }


def main():
    """Command-line interface for project management."""
    import argparse
    
    parser = argparse.ArgumentParser(description="RISC-V Rust Project Manager")
    subparsers = parser.add_subparsers(dest="command", help="Available commands")
    
    # List projects command
    subparsers.add_parser("list", help="List all projects")
    
    # Info command
    info_parser = subparsers.add_parser("info", help="Show project information")
    info_parser.add_argument("name", help="Project name")
    
    args = parser.parse_args()
    
    if not args.command:
        parser.print_help()
        return
    
    manager = ProjectManager(Path.cwd())
    
    try:
        if args.command == "list":
            projects = manager.list_projects()
            if projects:
                print("Projects:")
                for project in projects:
                    print(f"  - {project}")
            else:
                print("No projects found")
        
        elif args.command == "info":
            info = manager.get_project_info(args.name)
            print(f"Project: {info['name']}")
            for key, value in info.items():
                if key != "name":
                    print(f"  {key}: {value}")
    
    except Exception as e:
        print(f"Error: {e}")
        return 1


if __name__ == "__main__":
    exit(main() or 0)
