{
  description = "RISC-V Rust Development Environment - A comprehensive environment for developing and testing Rust applications on RISC-V cores";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs = {
        nixpkgs.follows = "nixpkgs";
      };
    };
  };

  outputs = { self, nixpkgs, flake-utils, rust-overlay, ... }:
    # Note: The "dirty Git tree" warning is expected during development
    # It can be ignored unless you're publishing this flake
    flake-utils.lib.eachDefaultSystem (system:
      let
        overlays = [ (import rust-overlay) ];
        pkgs = import nixpkgs {
          inherit system overlays;
        };
        
        # Rust nightly with RISC-V target
        rustToolchain = pkgs.rust-bin.nightly.latest.default.override {
          targets = [ "riscv32i-unknown-none-elf" ];
          extensions = [ "rust-src" "cargo" "rustc" "rust-analyzer" ];
        };

        # Python environment with dependencies
        pythonEnv = pkgs.python3.withPackages (ps: with ps; [
          pytest
          pytest-xdist
          pyyaml
          rich
          click
          mypy
          black
          flake8
        ]);

                # RISC-V toolchain with fallbacks for different Nixpkgs versions
        riscvToolchain = let
          # Try different possible package names across Nixpkgs versions
          candidates = [
            "riscv64-embedded-toolchain"
            "riscv-toolchain"
            "riscv64-unknown-elf-gcc"
            "riscv64-unknown-elf-toolchain"
          ];
          
          # Find the first available package
          findToolchain = names:
            if names == [] then null
            else if pkgs ? ${builtins.head names} then pkgs.${builtins.head names}
            else findToolchain (builtins.tail names);
            
          # Get the toolchain or use a placeholder if none found
          toolchain = findToolchain candidates;
        in 
          if toolchain != null then toolchain
          else (pkgs.symlinkJoin {
            name = "riscv-minimal-toolchain";
            paths = with pkgs; [
              # Use individual tools as fallback
              (lib.optional (pkgs ? riscv64-unknown-elf-binutils) riscv64-unknown-elf-binutils)
              (lib.optional (pkgs ? riscv64-unknown-elf-gcc) riscv64-unknown-elf-gcc)
              # If all else fails, at least include LLVM which can handle RISC-V
              llvmPackages.bintools
              llvmPackages.lld
            ];
          });
        
      in {
        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            # Rust
            rustToolchain
            
            # RISC-V tools
            riscvToolchain
            
            # Verilog simulation - conditionally include if available
            (lib.optional (lib.hasAttr "icarus-verilog" pkgs) icarus-verilog)
            (lib.optional (lib.hasAttr "gtkwave" pkgs) gtkwave)
            
            # Python
            pythonEnv
            uv
            
            # Build tools
            gnumake
            pkg-config
            
            # Utilities
            bash
            coreutils
            llvmPackages.bintools
          ];

          shellHook = ''
            # Set environment variables
            export PATH=$PATH:''${HOME}/.cargo/bin
            
            # Welcome message
            echo "RISC-V Rust Development Environment activated!"
            echo "-------------------------------------------"
            echo "Run 'make help' to see available commands"
            
            # Check if cargo-binutils is installed
            if ! command -v cargo-objcopy &>/dev/null; then
              echo -e "\n⚠️  cargo-binutils is not installed but is required for some commands."
              echo "   You can install it manually with: cargo install cargo-binutils"
            fi
            
            # Create a virtual environment if it doesn't exist
            if command -v uv &>/dev/null && [ ! -d ".venv" ]; then
              echo "Creating Python virtual environment..."
              uv venv -p python3 .venv
              if [ -f "requirements.txt" ]; then
                uv pip install --python ./.venv/bin/python3 -r requirements.txt
              fi
            elif [ ! -d ".venv" ] && command -v python3 &>/dev/null; then
              echo "Creating Python virtual environment with standard tools..."
              python3 -m venv .venv
              if [ -f "requirements.txt" ]; then
                ./.venv/bin/pip install -r requirements.txt
              fi
            fi
          '';

          # Set environment variables
          RUST_SRC_PATH = "${rustToolchain}/lib/rustlib/src/rust/library";
        };
      }
    );
}
