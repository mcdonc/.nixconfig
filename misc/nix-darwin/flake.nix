{
  description = "Example Darwin system flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin.url = "github:LnL7/nix-darwin";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    nix-homebrew.url = "github:zhaofengli-wip/nix-homebrew";
  };

  outputs = inputs@{ self, nix-darwin, nixpkgs, home-manager, nix-homebrew }:
  {
    # Build darwin flake using:
    # $ darwin-rebuild build --flake .#simple
    darwinConfigurations."admins-iMac-Pro" = nix-darwin.lib.darwinSystem {
      modules = [
        ./configuration.nix
        nix-homebrew.darwinModules.nix-homebrew {
          nix-homebrew = {
            enable = true;
            user = "chrism";
          };
        }
        home-manager.darwinModules.home-manager {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.users.chrism = import ./home.nix;
        }
      ];
      specialArgs = { inherit inputs; };
    };
    darwinConfigurations."thinknix52-mac" = nix-darwin.lib.darwinSystem {
      modules = [
        ./configuration.nix
        nix-homebrew.darwinModules.nix-homebrew {
          nix-homebrew = {
            enable = true;
            user = "chrism";
          };
        }
        home-manager.darwinModules.home-manager {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.users.chrism = import ./home.nix;
        }
      ];
      specialArgs = { inherit inputs; };
    };
    # Expose the package set, including overlays, for convenience.
    darwinPackages = self.darwinConfigurations."admins-iMac-Pro".pkgs;

  };
}
