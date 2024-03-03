{
  description = "Chris' Jawns";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-23.11";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs-py36.url =
      "github:NixOS/nixpkgs/407f8825b321617a38b86a4d9be11fd76d513da2";
    nixpkgs-py37.url =
      "github:NixOS/nixpkgs/79b3d4bcae8c7007c9fd51c279a8a67acfa73a2a";
    nixpkgs-py39.url =
      "github:NixOS/nixpkgs/fe7ab74a86d78ba00d144aa7a8da8c71a200c563";
    nixpkgs-keybase-bumpversion.url =
      "github:mcdonc/nixpkgs/keybase-bumpversion";
    nixpkgs-olive.url =
      "github:NixOS/nixpkgs/0aca8f43c8dba4a77aa0c16fb0130237c3da514c";
    nixos-hardware.url = "github:NixOS/nixos-hardware";
    nixgl-olive.url = "github:guibou/nixGL";
    nixgl-olive.inputs.nixpkgs.follows = "nixpkgs-olive";
    nixgl-unstable.url = "github:guibou/nixGL";
    nixgl-unstable.inputs.nixpkgs.follows = "nixpkgs-unstable";

    home-manager.url = "github:nix-community/home-manager/release-23.11";
    nix-gaming.url = "github:fufexan/nix-gaming";
    nixtheplanet.url = "github:matthewcroughan/NixThePlanet";
    #kde2nix.url = "github:nix-community/kde2nix";
    # nixpkgs-bgremoval.url = "github:mcdonc/nixpkgs/newer-obs-bgremoval";
    # plasma-manager.url =
    #  "github:mcdonc/plasma-manager/enable-look-and-feel-settings";
    # plasma-manager.inputs.nixpkgs.follows = "nixpkgs";
    # plasma-manager.inputs.home-manager.follows = "home-manager";
    # agenix.url = "github:ryantm/agenix";
    # nur.url = "github:nix-community/NUR";
  };

  outputs =
    { self
    , nixpkgs
    , nix
    , nixos-hardware
    , home-manager
    , nixpkgs-olive
    , nixpkgs-unstable
    , nixpkgs-py36
    , nixpkgs-py37
    , nixpkgs-py39
    , nixpkgs-keybase-bumpversion
    , nix-gaming
    , nixtheplanet
    , nixgl-olive
    , nixgl-unstable
    }@inputs:
    let
      my_overlay = (self: super: {
        steam = super.steam.override {
          extraProfile = "export STEAM_EXTRA_COMPAT_TOOLS_PATHS='${
              nix-gaming.packages.${system}.proton-ge
            }'";
        };
        # prevent openssh from checking perms of ~/.ssh/config to appease vscode
        # https://github.com/nix-community/home-manager/issues/322
        openssh = super.openssh.overrideAttrs (old: {
          patches = (old.patches or [ ]) ++ [
            ./patches/openssh-dontcheckconfigperms.patch
          ];
          doCheck = false;
        });
      });

      overlays = [ my_overlay ];

      system = "x86_64-linux";
      specialArgs = {
        pkgs-unstable = import nixpkgs-unstable {
          inherit system;
          config.allowUnfree = true;
        };
        pkgs-olive = import nixpkgs-olive {
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
        pkgs-py39 = import nixpkgs-py39 {
          inherit system;
          config.allowUnfree = true;
        };
        pkgs-keybase-bumpversion = import nixpkgs-keybase-bumpversion {
          inherit system;
          config.allowUnfree = true;
        };
        bigger-darwin = nixtheplanet.legacyPackages.x86_64-linux.makeDarwinImage {
          diskSizeBytes = 100000000000;
        };
        nixgl-olive = nixgl-olive.defaultPackage.x86_64-linux.nixGLIntel;
        nixgl-unstable = nixgl-unstable.defaultPackage.x86_64-linux.nixGLIntel;

        inherit nixos-hardware nix-gaming system inputs;
      };

      chris-modules = [
        ./users/chrism/user.nix
        home-manager.nixosModules.home-manager
        nixtheplanet.nixosModules.macos-ventura
        {
          home-manager = {
            useUserPackages = true;
            users.chrism = import ./users/chrism/hm.nix;
            extraSpecialArgs = specialArgs;
          };
        }
        ({ config, pkgs, ... }: { nixpkgs.overlays = overlays; })
      ];
      larry-modules = [
        ./users/larry/user.nix
        home-manager.nixosModules.home-manager
        nixtheplanet.nixosModules.macos-ventura
        {
          home-manager = {
            useUserPackages = true;
            users.larry = import ./users/larry/hm.nix;
            extraSpecialArgs = specialArgs;
          };
        }
        ({ config, pkgs, ... }: { nixpkgs.overlays = overlays; })
      ];
      larry-and-chris-modules = [
        ./users/larry/user.nix
        ./users/chrism/user.nix
        home-manager.nixosModules.home-manager
        nixtheplanet.nixosModules.macos-ventura
        {
          home-manager = {
            useUserPackages = true;
            users.larry = import ./users/larry/hm.nix;
            users.chrism = import ./users/chrism/hm.nix;
            extraSpecialArgs = specialArgs;
          };
        }
        ({ config, pkgs, ... }: { nixpkgs.overlays = overlays; })
      ];
    in
    {
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
        nixcentre = nixpkgs.lib.nixosSystem {
          inherit system specialArgs;
          modules = chris-modules ++ [ ./hosts/nixcentre.nix ];
        };
        nixos-vm = nixpkgs.lib.nixosSystem {
          inherit system specialArgs;
          modules = chris-modules ++ [ ./hosts/nixos-vm.nix ];
        };
      };
    };
}
