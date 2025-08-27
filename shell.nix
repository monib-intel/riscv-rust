# shell.nix - For compatibility with older Nix installations without flakes enabled
# This file allows users with traditional nix-shell to use the same development
# environment as those using the newer flakes approach.

(import (
  fetchTarball {
    url = "https://github.com/edolstra/flake-compat/archive/master.tar.gz";
    sha256 = "1prd9b1xx8c0sfwnyzkspplh30m613j42l1k789s521f4kv4c2z2";
  }
) {
  src = ./.;
}).defaultNix.devShells.${builtins.currentSystem}.default
