{
  description = "Build environment with packer and friends.";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = {
    self,
    nixpkgs,
    flake-utils,
  }:
    flake-utils.lib.eachDefaultSystem (system: let
      pkgs = import nixpkgs {
        inherit system;
        config = {
          # Allow packer with unfree lisence
          allowUnfreePredicate = pkg:
            builtins.elem (pkg.pname or pkg.name) [
              "packer"
            ];
        };
      };
    in {
      devShells.default = pkgs.mkShell {
        buildInputs = with pkgs; [
          qemu
          packer
          wget
          gnupg
        ];

        shellHook = ''
          echo "Initializing packer plugins..."
          packer init archlinux.pkr.hcl
        '';
      };
    });
}
