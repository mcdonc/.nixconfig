{
  description = "Chris' Jawns";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs-2411.url = "github:NixOS/nixpkgs/nixos-24.11";
    nixpkgs-py36.url = "github:NixOS/nixpkgs/407f8825b321617a38b86a4d9be11fd76d513da2";
    nixpkgs-py37.url = "github:NixOS/nixpkgs/79b3d4bcae8c7007c9fd51c279a8a67acfa73a2a";
    nixpkgs-py39.url = "github:NixOS/nixpkgs/fe7ab74a86d78ba00d144aa7a8da8c71a200c563";
    nixpkgs-olive.url = "github:NixOS/nixpkgs/0aca8f43c8dba4a77aa0c16fb0130237c3da514c";
    nixos-hardware.url = "github:NixOS/nixos-hardware";
    nixgl-olive.url = "github:guibou/nixGL";
    nixgl-olive.inputs.nixpkgs.follows = "nixpkgs-olive";
    nixgl-unstable.url = "github:guibou/nixGL";
    nixgl-unstable.inputs.nixpkgs.follows = "nixpkgs-unstable";

    home-manager.url = "github:nix-community/home-manager/release-25.05";
    musnix.url = "github:musnix/musnix";
    musnix.inputs.nixpkgs.follows = "nixpkgs";
    nixtheplanet.url = "github:matthewcroughan/NixThePlanet";
    isd.url = "github:isd-project/isd";
    agenix.url = "github:ryantm/agenix";
    nixos-generators.url = "github:nix-community/nixos-generators";
    nixos-generators.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = inputs:
    let

      system = "x86_64-linux";

      nixgl-olive = inputs.nixgl-olive.defaultPackage."${system}".nixGLIntel;
      nixgl-unstable = inputs.nixgl-unstable.defaultPackage."${system}".nixGLIntel;
      my_overlay = (
        self: super: { }
      );

      forkInputs = with inputs; [
        { name = "pkgs-unstable"; value = nixpkgs-unstable; }
        { name = "pkgs-2411"; value = nixpkgs-2411; }
        { name = "pkgs-olive"; value = nixpkgs-olive; }
        { name = "pkgs-py36"; value = nixpkgs-py36; }
        { name = "pkgs-py37"; value = nixpkgs-py37; }
        { name = "pkgs-py39"; value = nixpkgs-py39; }
      ];
      mkNpFork = forkinput: {
        name = forkinput.name;
        value = import forkinput.value {
          inherit system;
          config.allowUnfree = true;
        };
      };
      forks = builtins.listToAttrs ((builtins.map (i: mkNpFork i)) forkInputs);
      mdi = inputs.nixtheplanet.legacyPackages."${system}".makeDarwinImage;
      specialArgs = inputs // forks // {
        bigger-darwin = mdi {
          diskSizeBytes = 100000000000;
        };
        inherit nixgl-olive nixgl-unstable system inputs;
      };

      shared-modules = [
        ./jawns.nix
        inputs.home-manager.nixosModules.home-manager
        inputs.nixtheplanet.nixosModules.macos-ventura
        inputs.musnix.nixosModules.musnix
        inputs.agenix.nixosModules.default
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
        "keithmoon"
        "arctor"
        "dodemo"
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
