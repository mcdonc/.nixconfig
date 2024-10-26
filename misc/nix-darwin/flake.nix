{
  description = "Example Darwin system flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin.url = "github:LnL7/nix-darwin";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = inputs@{ self, nix-darwin, nixpkgs, home-manager }:
  {
    # Build darwin flake using:
    # $ darwin-rebuild build --flake .#simple
    darwinConfigurations."admins-iMac-Pro" = nix-darwin.lib.darwinSystem {
      modules = [ ./configuration.nix ];
      specialArgs = { inherit inputs; };
    };

    # Expose the package set, including overlays, for convenience.
    darwinPackages = self.darwinConfigurations."admins-iMac-Pro".pkgs;

    defaultPackage.x86_64-darwin = home-manager.defaultPackage.x86_64-darwin;
    homeConfigurations = {
      "chrism" = home-manager.lib.homeManagerConfiguration {
        pkgs = import nixpkgs { system = "x86_64-darwin"; };
        modules = [ ./home.nix ];
      };
    };
  };
}
