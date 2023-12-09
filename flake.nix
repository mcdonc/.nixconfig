{
  description = "Chris' Jawns";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-23.11";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs-py36.url =
      "github:NixOS/nixpkgs/407f8825b321617a38b86a4d9be11fd76d513da2";
    nixpkgs-py37.url =
      "github:NixOS/nixpkgs/79b3d4bcae8c7007c9fd51c279a8a67acfa73a2a";
    nixos-hardware.url = "github:NixOS/nixos-hardware";
    home-manager.url = "github:nix-community/home-manager/release-23.11";
    nixpkgs-r2211.url = "github:NixOS/nixpkgs/nixos-22.11";
    nix-gaming.url = "github:fufexan/nix-gaming";
    kde2nix.url = "github:nix-community/kde2nix";
    nixtheplanet.url = "github:matthewcroughan/NixThePlanet";
    # nixpkgs-bgremoval.url = "github:mcdonc/nixpkgs/newer-obs-bgremoval";
    # nixpkgs-oldfirefox.url =
    #   "github:NixOS/nixpkgs/cfe01551540042983152c147bb158a69cbd48462";
    # plasma-manager.url =
    #  "github:mcdonc/plasma-manager/enable-look-and-feel-settings";
    # plasma-manager.inputs.nixpkgs.follows = "nixpkgs";
    # plasma-manager.inputs.home-manager.follows = "home-manager";
    # agenix.url = "github:ryantm/agenix";
  };

  outputs = { self, nixpkgs, nix, nixos-hardware, home-manager, nixpkgs-r2211
    , nixpkgs-unstable, nixpkgs-py36, nixpkgs-py37, nix-gaming, kde2nix
    , nixtheplanet }@inputs:
    let
      overlays = (self: super: {
        steam = super.steam.override {
          extraProfile = "export STEAM_EXTRA_COMPAT_TOOLS_PATHS='${
              nix-gaming.packages.${system}.proton-ge
            }'";
        };
        # for NixThePlanet, see
        # https://gist.github.com/mcdonc/872a16354d1cd8219a188bc443e0a997
        # see https://stackoverflow.com/questions/70395839/how-to-globally-override-a-pythonpackage-in-nix
        python311 = super.python311.override {
          packageOverrides = pyself: pysuper: {
            vncdo = pysuper.vncdo.overrideAttrs (_: {
              setuptoolsCheckPhase = "true";
              doCheck = false;
            });
          };
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
        pkgs-py36 = import nixpkgs-py36 {
          inherit system;
          config.allowUnfree = true;
        };
        pkgs-py37 = import nixpkgs-py37 {
          inherit system;
          config.allowUnfree = true;
        };
        # pkgs-bgremoval = import nixpkgs-bgremoval {
        #   inherit system;
        #   config.allowUnfree = true;
        # };
        # pkgs-oldfirefox = import nixpkgs-oldfirefox {
        #   inherit system;
        #   config.allowUnfree = true;
        # };
        inherit nixos-hardware nix-gaming system inputs kde2nix;
      };

      chris-modules = [
        ./users/chrism/user.nix
        home-manager.nixosModules.home-manager
        kde2nix.nixosModules.plasma6
        nixtheplanet.nixosModules.macos-ventura
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
      larry-and-chris-modules = [
        ./users/larry/user.nix
        ./users/chrism/user.nix
        home-manager.nixosModules.home-manager
        {
          home-manager = {
            useUserPackages = true;
            users.larry = import ./users/larry/hm.nix;
            users.chrism = import ./users/chrism/hm.nix;
            extraSpecialArgs = specialArgs;
          };
        }
        ({ config, pkgs, ... }: { nixpkgs.overlays = [ overlays ]; })
      ];
    in {
      nixosConfigurations = {
        thinknix512 = nixpkgs.lib.nixosSystem {
          inherit system specialArgs;
          modules = chris-modules ++ [ ./hosts/thinknix512.nix ];
        };
        thinknix50 = nixpkgs.lib.nixosSystem {
          inherit system specialArgs;
          modules = chris-modules ++ [ ./hosts/thinknix50.nix ];
        };
        thinknix52 = nixpkgs.lib.nixosSystem {
          inherit system specialArgs;
          modules = chris-modules ++ [ ./hosts/thinknix52.nix ];
        };
        thinknix51 = nixpkgs.lib.nixosSystem {
          inherit system specialArgs;
          modules = larry-and-chris-modules ++ [ ./hosts/thinknix51.nix ];
        };
        thinknix420 = nixpkgs.lib.nixosSystem {
          inherit system specialArgs;
          modules = chris-modules ++ [ ./hosts/thinknix420.nix ];
        };
        thinkcentre1 = nixpkgs.lib.nixosSystem {
          inherit system specialArgs;
          modules = chris-modules ++ [ ./hosts/thinkcentre1.nix ];
        };
        optinix = nixpkgs.lib.nixosSystem {
          inherit system specialArgs;
          modules = chris-modules ++ [ ./hosts/optinix.nix ];
        };
        nixos = nixpkgs.lib.nixosSystem {
          inherit system specialArgs;
          modules = chris-modules ++ [ ./hosts/nixos-vm.nix ];
        };
      };
    };
}
