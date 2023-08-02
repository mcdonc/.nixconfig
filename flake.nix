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
      specialargs = {
        pkgs-unstable = import nixpkgs-unstable {
          inherit system;
          config.allowUnfree = true;
        };
        pkgs-r2211 = import nixpkgs-r2211 {
          inherit system;
          config.allowUnfree = true;
        };
        inherit nixos-hardware;
        inherit system;
        inherit inputs;
      };

      chris-modules = [
        ./users/chrism/user.nix
        home-manager.nixosModules.home-manager {
          home-manager = {
            useUserPackages = true;
            users.chrism = import ./users/chrism/hm.nix;
            extraSpecialArgs = specialargs;
          };
        }
      ];
    in {
      nixosConfigurations = {
        thinknix512 = nixpkgs.lib.nixosSystem {
          inherit system;
          modules = chris-modules ++ [
            ./hosts/thinknix512.nix
          ];
          specialArgs = specialargs;
        };
        thinknix50 = nixpkgs.lib.nixosSystem {
          inherit system;
          modules = chris-modules ++ [
            ./hosts/thinknix50.nix
          ];
          specialArgs = { inherit specialargs; };
        };
        thinknix52 = nixpkgs.lib.nixosSystem {
          inherit system;
          modules = chris-modules ++ [
            ./hosts/thinknix52.nix
          ];
          specialArgs = specialargs;
        };
        thinknix51 = nixpkgs.lib.nixosSystem {
          inherit system;
          modules = [
            ./hosts/thinknix51.nix
            ./users/larry/user.nix
            home-manager.nixosModules.home-manager
            {
              home-manager.useUserPackages = true;
              home-manager.users.larry = import ./users/larry/hm.nix;
            }
          ];
          specialArgs = { inherit specialargs; };
        };
        thinknix420 = nixpkgs.lib.nixosSystem {
          inherit system;
          modules = chris-modules ++ [
            ./hosts/thinknix420.nix
          ];
          specialArgs = specialargs;
        };
      };
    };
}
