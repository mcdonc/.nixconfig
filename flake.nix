{
  description = "Chris' Jawns";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-23.11";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs-py36.url = "github:NixOS/nixpkgs/407f8825b321617a38b86a4d9be11fd76d513da2";
    nixpkgs-py37.url = "github:NixOS/nixpkgs/79b3d4bcae8c7007c9fd51c279a8a67acfa73a2a";
    nixpkgs-py39.url = "github:NixOS/nixpkgs/fe7ab74a86d78ba00d144aa7a8da8c71a200c563";
    nixpkgs-kb-bumpversion.url = "github:mcdonc/nixpkgs/keybase-bumpversion";
    nixpkgs-olive.url = "github:NixOS/nixpkgs/0aca8f43c8dba4a77aa0c16fb0130237c3da514c";
    nixos-hardware.url = "github:NixOS/nixos-hardware";
    nixgl-olive.url = "github:guibou/nixGL";
    nixgl-olive.inputs.nixpkgs.follows = "nixpkgs-olive";
    nixgl-unstable.url = "github:guibou/nixGL";
    nixgl-unstable.inputs.nixpkgs.follows = "nixpkgs-unstable";

    home-manager.url = "github:nix-community/home-manager/release-23.11";
    nix-gaming.url = "github:fufexan/nix-gaming";
    musnix.url = "github:musnix/musnix";
    musnix.inputs.nixpkgs.follows = "nixpkgs";
    nixtheplanet.url = "github:matthewcroughan/NixThePlanet";
    # nixpkgs-bgremoval.url = "github:mcdonc/nixpkgs/newer-obs-bgremoval";
    # agenix.url = "github:ryantm/agenix";
    # nur.url = "github:nix-community/NUR";
  };

  outputs = inputs:
    let

      system = "x86_64-linux";

      nixgl-olive = inputs.nixgl-olive.defaultPackage."${system}".nixGLIntel;
      nixgl-unstable = inputs.nixgl-unstable.defaultPackage."${system}".nixGLIntel;
      ge = inputs.nix-gaming.packages."${system}".proton-ge;

      my_overlay = (
        self: super: {
          steam = super.steam.override {
            extraProfile = "export STEAM_EXTRA_COMPAT_TOOLS_PATHS='${ge}'";
          };
        }
      );

      forkInputs = with inputs; [
        { name = "pkgs-unstable"      ; value=nixpkgs-unstable;         }
        { name = "pkgs-olive"         ; value=nixpkgs-olive;            }
        { name = "pkgs-py36"          ; value=nixpkgs-py36;             }
        { name = "pkgs-py37"          ; value=nixpkgs-py37;             }
        { name = "pkgs-py39"          ; value=nixpkgs-py39;             }
        { name = "pkgs-kb-bumpversion"; value = nixpkgs-kb-bumpversion; }
      ];
      mkNpFork = forkinput: {
        name = forkinput.name;
        value = import forkinput.value {
          inherit system;
          config.allowUnfree = true;
        };
      };
      forks = builtins.listToAttrs ((builtins.map (i: mkNpFork i)) forkInputs);
      specialArgs = inputs // forks // {
        bigger-darwin = inputs.nixtheplanet.legacyPackages."${system}".makeDarwinImage {
          diskSizeBytes = 100000000000;
        };
        inherit nixgl-olive nixgl-unstable system;
      };

      shared-modules = [
        inputs.home-manager.nixosModules.home-manager
        inputs.nixtheplanet.nixosModules.macos-ventura
        inputs.musnix.nixosModules.musnix
        (
          { config, pkgs, ... }:
          {
            nixpkgs.overlays = [ my_overlay ];
          }
        )
        {
          home-manager = {
            useUserPackages = true;
            extraSpecialArgs = specialArgs;
          };
        }
      ];
    in
      let
        hosts = [
          "thinknix50"
          "thinknix51"
          "thinknix512"
          "thinknix52"
          "thinkcentre"
          "optinix"
          "nixcentre"
          "nixos_vm"
        ];
        mkSystem = host: {
          name = host;
          value = inputs.nixpkgs.lib.nixosSystem {
            inherit system specialArgs;
            modules = shared-modules ++ [ (./. + "/hosts/${host}.nix") ];
          };
        };
        configs = builtins.listToAttrs ((builtins.map (h: mkSystem h)) hosts);
      in
        {
          nixosConfigurations = configs;
        };
}
