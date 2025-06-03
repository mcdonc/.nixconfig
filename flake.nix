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

    home-manager.url = "github:nix-community/home-manager/release-25.05";
    musnix.url = "github:musnix/musnix";
    musnix.inputs.nixpkgs.follows = "nixpkgs";
    nixtheplanet.url = "github:matthewcroughan/NixThePlanet";
    agenix.url = "github:ryantm/agenix";
    agenix.inputs.nixpkgs.follows = "nixpkgs";
    nixos-generators.url = "github:nix-community/nixos-generators";
    nixos-generators.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = inputs:
    let

      my_overlay = (
        self: super: { }
      );

      mkSystem = host:
        let
          shared-mods = [
            ./jawns.nix
            inputs.home-manager.nixosModules.home-manager
            inputs.agenix.nixosModules.default
            #inputs.nixtheplanet.nixosModules.macos-ventura
            #inputs.musnix.nixosModules.musnix
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
          forkInputs = with inputs; [
            { name = "pkgs-unstable";     value = nixpkgs-unstable; }
            { name = "pkgs-2411";         value = nixpkgs-2411; }
            { name = "pkgs-olive";        value = nixpkgs-olive; }
            { name = "pkgs-py36";         value = nixpkgs-py36; }
            { name = "pkgs-py37";         value = nixpkgs-py37; }
            { name = "pkgs-py39";         value = nixpkgs-py39; }
          ];
          mkNpFork = forkinput: {
            name = forkinput.name;
            value = import forkinput.value {
              system = host.system;
              config.allowUnfree = true;
            };
          };
          forks = builtins.listToAttrs ((builtins.map (i: mkNpFork i)) forkInputs);
          # mdi = inputs.nixtheplanet.legacyPackages."${host.system}".makeDarwinImage;
          specialArgs = inputs // forks // {
            # bigger-darwin = mdi {
            #   diskSizeBytes = 100000000000;
            # };
            system = host.system;
            inherit inputs;
          };

        in {
          name = host.hostname;
          value = inputs.nixpkgs.lib.nixosSystem {
            system = host.system;
            inherit specialArgs;
            modules = shared-mods ++ [(./. + "/hosts/${host.hostname}.nix")];
          };
        };

      hosts = [
        { hostname = "thinknix50";        system = "x86_64-linux"; }
        { hostname = "thinknix51";        system = "x86_64-linux"; }
        { hostname = "thinknix512";       system = "x86_64-linux"; }
        { hostname = "thinknix52";        system = "x86_64-linux"; }
        { hostname = "thinkcentre";       system = "x86_64-linux"; }
        { hostname = "optinix";           system = "x86_64-linux"; }
        { hostname = "nixcentre";         system = "x86_64-linux"; }
        { hostname = "nixos_vm";          system = "x86_64-linux"; }
        { hostname = "keithmoon";         system = "x86_64-linux"; }
        { hostname = "arctor";            system = "x86_64-linux"; }
        { hostname = "dodemo";            system = "x86_64-linux"; }
        { hostname = "lock802";           system = "aarch64-linux"; }
        { hostname = "clonelock802";      system = "aarch64-linux"; }
      ];
      configs = builtins.listToAttrs ((builtins.map (h: mkSystem h)) hosts);
    in
    {
      nixosConfigurations = configs;
    };
}
