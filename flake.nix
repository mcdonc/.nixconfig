{
  description = "Chris' Jawns";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-23.05";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixos-hardware.url = "github:NixOS/nixos-hardware";
    home-manager.url = "github:nix-community/home-manager/release-23.05";
    nixpkgs-r2211.url = "github:NixOS/nixpkgs/nixos-22.11";
    agenix.url = "github:ryantm/agenix";
  };

  outputs = { self, nixpkgs, nix, nixos-hardware, home-manager, nixpkgs-r2211
    , nixpkgs-unstable, agenix }@inputs:
    let
      system = "x86_64-linux";
      overlay-nixpkgs = final: prev: {
        r2211 = import nixpkgs-r2211 {
          inherit system;
          config.allowUnfree = true;
        };
        unstable = import nixpkgs-unstable {
          inherit system;
          config.allowUnfree = true;
        };
      };
      chris-modules = [
        ./users/chrism/user.nix
        home-manager.nixosModules.home-manager
        agenix.nixosModules.default
        {
          home-manager.useUserPackages = true;
          home-manager.users.chrism = import ./users/chrism/hm.nix;
        }
      ];
    in {
      nixosConfigurations = {
        thinknix512 = nixpkgs.lib.nixosSystem {
          inherit system;
          modules = chris-modules ++ [
            ({ config, pkgs, ... }: { nixpkgs.overlays = [ overlay-nixpkgs ]; })
            nixos-hardware.nixosModules.lenovo-thinkpad-p51
            ./hosts/thinknix512.nix
          ];
        };
        thinknix50 = nixpkgs.lib.nixosSystem {
          inherit system;
          modules = chris-modules ++ [
            ({ config, pkgs, ... }: { nixpkgs.overlays = [ overlay-nixpkgs ]; })
            nixos-hardware.nixosModules.lenovo-thinkpad-p50
            ./hosts/thinknix50.nix
          ];
        };
        thinknix52 = nixpkgs.lib.nixosSystem {
          inherit system;
          modules = chris-modules ++ [
            ({ config, pkgs, ... }: { nixpkgs.overlays = [ overlay-nixpkgs ]; })
            nixos-hardware.nixosModules.lenovo-thinkpad-p52
            ./hosts/thinknix52.nix
          ];
        };
        thinknix51 = nixpkgs.lib.nixosSystem {
          inherit system;
          modules = [
            ({ config, pkgs, ... }: { nixpkgs.overlays = [ overlay-nixpkgs ]; })
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
          modules = chris-modules ++ [
            ({ config, pkgs, ... }: { nixpkgs.overlays = [ overlay-nixpkgs ]; })
            nixos-hardware.nixosModules.lenovo-thinkpad-t420
            ./hosts/thinknix420.nix
          ];
        };
      };
    };
}
