{
  inputs = {
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs.url = "github:nixos/nixpkgs/nixos-23.05";
    flake-utils.url = "github:numtide/flake-utils";
  };
  outputs = { nixpkgs, nixpkgs-unstable, flake-utils, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          config = { allowUnfree = true; };
        };
        unstable = import nixpkgs-unstable {
          inherit system;
          config = { allowUnfree = true; };
        };
        onnxruntime = (with pkgs; callPackage ./onnxruntime.nix { unstable = unstable; });
      in rec {
        defaultApp = flake-utils.lib.mkApp { drv = defaultPackage; };
        defaultPackage = onnxruntime;
        devShell = pkgs.mkShell { buildInputs = [ onnxruntime ]; };
      });
}
