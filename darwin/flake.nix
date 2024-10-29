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
  let
    hm-config = {
      home-manager = {
        useGlobalPkgs = true;
        useUserPackages = true;
      };
    };
    homebrew-config = {
      nix-homebrew = {
        enable = true;
        enableRosetta = false;
      };
    };
    shared-modules = [
      ./configuration.nix
      home-manager.darwinModules.home-manager
      nix-homebrew.darwinModules.nix-homebrew
      hm-config
      homebrew-config
    ];
  in
    {
      darwinConfigurations."keithmoon-mac" = nix-darwin.lib.darwinSystem {
        modules = shared-modules;
        specialArgs = { inherit inputs; system="x86_64-darwin";};
      };
      darwinConfigurations."thinknix52-mac" = nix-darwin.lib.darwinSystem {
        modules = shared-modules;
        specialArgs = { inherit inputs; system="x86_64-darwin";};
      };
    };
}
