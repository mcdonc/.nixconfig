{
  description = "Chris' Jawns";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-23.05";
    nixos-hardware.url = "github:NixOS/nixos-hardware";
    home-manager.url = "github:nix-community/home-manager/release-23.05";
    nixpkgs-r2211.url = "github:NixOS/nixpkgs/nixos-22.11";
    nixpkgs-python.url = "github:cachix/nixpkgs-python";
  };

  outputs = { self, nixpkgs, nix, nixos-hardware, home-manager, nixpkgs-r2211
    , nixpkgs-python }@inputs:
    let
      system = "x86_64-linux";
      overlay-r2211 = final: prev: {
        r2211 = import nixpkgs-r2211 {
          inherit system;
          config.allowUnfree = true;
        };
      };
      overlay-nixpkgs-python = final: prev: {
        allthepythons = import nixpkgs-python;
      };
    in {
      nixosConfigurations = {
        thinknix512 = nixpkgs.lib.nixosSystem {
          inherit system;
          modules = [
            ({ config, pkgs, ... }: { nixpkgs.overlays = [ overlay-r2211 ]; })
            nixos-hardware.nixosModules.lenovo-thinkpad-p51
            ./hosts/thinknix512.nix
            ./users/chrism/user.nix
            home-manager.nixosModules.home-manager
            {
              home-manager.useUserPackages = true;
              home-manager.users.chrism = import ./users/chrism/hm.nix;
            }
          ];
        };
        thinknix50 = nixpkgs.lib.nixosSystem {
          inherit system;
          modules = [
            ({ config, pkgs, ... }: { nixpkgs.overlays = [ overlay-r2211 ]; })
            nixos-hardware.nixosModules.lenovo-thinkpad-p50
            ./hosts/thinknix50.nix
            ./users/chrism/user.nix
            home-manager.nixosModules.home-manager
            {
              home-manager.useUserPackages = true;
              home-manager.users.chrism = import ./users/chrism/hm.nix;
            }
          ];
        };
        thinknix52 = nixpkgs.lib.nixosSystem {
          inherit system;
          modules = [
            ({ config, pkgs, ... }: { nixpkgs.overlays = [ overlay-r2211 ]; })
            nixos-hardware.nixosModules.lenovo-thinkpad-p52
            ./hosts/thinknix52.nix
            ./users/chrism/user.nix
            home-manager.nixosModules.home-manager
            {
              home-manager.useUserPackages = true;
              home-manager.users.chrism = import ./users/chrism/hm.nix;
            }
          ];
        };
        thinknix51 = nixpkgs.lib.nixosSystem {
          inherit system;
          modules = [
            ({ config, pkgs, ... }: { nixpkgs.overlays = [ overlay-r2211 ]; })
            nixos-hardware.nixosModules.lenovo-thinkpad-p51
            ./hosts/thinknix51.nix
            ./users/larry/user.nix
            home-manager.nixosModules.home-manager
            {
              home-manager.useUserPackages = true;
              home-manager.users.larry = import ./users/larry/hm.nix;
            }
          ];
        };
        thinknix420 = nixpkgs.lib.nixosSystem {
          inherit system;
          modules = [
            ({ config, pkgs, ... }: { nixpkgs.overlays = [ overlay-r2211 ]; })
            nixos-hardware.nixosModules.lenovo-thinkpad-t420
            ./hosts/thinknix420.nix
            ./users/chrism/user.nix
            home-manager.nixosModules.home-manager
            {
              home-manager.useUserPackages = true;
              home-manager.users.chrism = import ./users/chrism/hm.nix;
            }
          ];
        };
      };
    };
  #home-manager https://github.com/nix-community/home-manager/archive/release-22.11.tar.gz
  #nixos https://nixos.org/channels/nixos-22.11
  #nixos-hardware https://github.com/NixOS/nixos-hardware/archive/master.tar.gz
  #nixos-hardware-fork https://github.com/mcdonc/nixos-hardware/archive/pseries-additions.tar.gz
}
