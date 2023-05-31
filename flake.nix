{
  description = "Chris' Jawns";

  inputs = {
    nixpkgs.url        = "github:NixOS/nixpkgs/nixos-22.11";
    nixos-hardware.url = "github:NixOS/nixos-hardware";
    home-manager = {
      url = "github:nix-community/home-manager/release-22.11";
#      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, nix, nixos-hardware, home-manager }: {
    nixosConfigurations = {
      thinknix512 = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          nixos-hardware.nixosModules.lenovo-thinkpad-p51
          ./hosts/thinknix512.nix
          ./users/chrism/user.nix
          home-manager.nixosModules.home-manager {
            home-manager.useUserPackages = true;
            home-manager.users.chrism = import ./users/chrism/hm.nix;
          }
        ];
      };
      thinknix50 = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          nixos-hardware.nixosModules.lenovo-thinkpad-p50
          ./hosts/thinknix50.nix
          ./users/chrism/user.nix
          home-manager.nixosModules.home-manager {
            home-manager.useUserPackages = true;
            home-manager.users.chrism = import ./users/chrism/hm.nix;
          }
        ];
      };
    };
  };
}
