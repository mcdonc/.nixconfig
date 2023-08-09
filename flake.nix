{
  description = "Chris' Jawns";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-23.05";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixos-hardware.url = "github:NixOS/nixos-hardware";
    home-manager.url = "github:nix-community/home-manager/release-23.05";
    nixpkgs-r2211.url = "github:NixOS/nixpkgs/nixos-22.11";
    plasma-manager.url =
      "github:mcdonc/plasma-manager/enable-look-and-feel-settings";
    plasma-manager.inputs.nixpkgs.follows = "nixpkgs";
    plasma-manager.inputs.home-manager.follows = "home-manager";
    nix-gaming.url = "github:fufexan/nix-gaming";
    agenix.url = "github:ryantm/agenix";
  };

  outputs = { self, nixpkgs, nix, nixos-hardware, home-manager, nixpkgs-r2211
    , nixpkgs-unstable, plasma-manager, nix-gaming, agenix }@inputs:
    let
      overlays = (_: prev: {
        steam = prev.steam.override {
          extraProfile = "export STEAM_EXTRA_COMPAT_TOOLS_PATHS='${
              nix-gaming.packages.${system}.proton-ge
            }'";
        };
      });
      system = "x86_64-linux";
      specialArgs = {
        pkgs-unstable = import nixpkgs-unstable {
          inherit system;
          config.allowUnfree = true;
        };
        pkgs-r2211 = import nixpkgs-r2211 {
          inherit system;
          config.allowUnfree = true;
        };
        inherit nixos-hardware;
        inherit plasma-manager;
        inherit nix-gaming;
        inherit system;
        inherit inputs;
      };
      overlay-obs-bgremoval = final: prev: {
        obs-studio-plugins = prev.obs-studio-plugins // {
          obs-backgroundremoval =
            prev.callPackage ./common/obs-backgroundremoval { };
        };
      };
      chris-modules = [
        ./users/chrism/user.nix
        home-manager.nixosModules.home-manager
        {
          home-manager = {
            useUserPackages = true;
            users.chrism = import ./users/chrism/hm.nix;
            extraSpecialArgs = specialArgs;
          };
        }
        ({ config, pkgs, ... }: { nixpkgs.overlays = [ overlays ]; })
      ];
      larry-modules = [
        ./users/larry/user.nix
        home-manager.nixosModules.home-manager
        {
          home-manager = {
            useUserPackages = true;
            users.larry = import ./users/larry/hm.nix;
            extraSpecialArgs = specialArgs;
          };
        }
        ({ config, pkgs, ... }: { nixpkgs.overlays = [ overlays ]; })
      ];
    in {
      nixosConfigurations = {
        thinknix512 = nixpkgs.lib.nixosSystem {
          inherit system;
          modules = chris-modules ++ [ ./hosts/thinknix512.nix ];
        };
        thinknix50 = nixpkgs.lib.nixosSystem {
          inherit system;
          inherit specialArgs;
          modules = chris-modules ++ [ ./hosts/thinknix50.nix ];
        };
        thinknix52 = nixpkgs.lib.nixosSystem {
          inherit system;
          inherit specialArgs;
          modules = chris-modules ++ [ ./hosts/thinknix52.nix ];
        };
        thinknix51 = nixpkgs.lib.nixosSystem {
          inherit system;
          inherit specialArgs;
          modules = larry-modules ++ [ ./hosts/thinknix51.nix ];
        };
        thinknix420 = nixpkgs.lib.nixosSystem {
          inherit system;
          inherit specialArgs;
          modules = chris-modules ++ [ ./hosts/thinknix420.nix ];
        };
        nixos = nixpkgs.lib.nixosSystem {
          inherit system;
          inherit specialArgs;
          modules = chris-modules ++ [ ./hosts/nixos-vm.nix ];
        };
      };
    };
}
