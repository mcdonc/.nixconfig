{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-23.11";
    systems.url = "github:nix-systems/default";
    devenv.url = "github:cachix/devenv/python-rewrite";
    nixpkgs-python.url = "github:cachix/nixpkgs-python";
    # these would be needed if devenv container <command> was supported
    nix2container.url = "github:nlewo/nix2container";
    nix2container.inputs.nixpkgs.follows = "nixpkgs";
    mk-shell-bin.url = "github:rrbutani/nix-mk-shell-bin";
  };

  nixConfig = {
    extra-trusted-public-keys =
      "devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw=";
    extra-substituters = "https://devenv.cachix.org";
  };

  outputs =
    { self, nixpkgs, devenv, systems, nix2container, mk-shell-bin, ... }@inputs:
    let
      forEachSystem = nixpkgs.lib.genAttrs (import systems);
      overlays = (self: super: {
        openssl = super.openssl.override {
          # overrides etc/ssl/openssl.cnf because SQL Server 2008 needs TLS 1.0
          conf = ./openssl.cnf;
        };
        python311 = super.python311.override {
          # nixos-23.11 sphinx wont build (tests fail), might work on unstable
          # need to override config.languages.python.package I think instead
          packageOverrides = pyself: pysuper: {
            sphinx = pysuper.sphinx.overrideAttrs (_: {
              pytestCheckPhase = "true";
              doCheck = false;
            });
          };
        };
      });
    in {
      packages = forEachSystem (system: {
        devenv-up = self.devShells.${system}.default.config.procfileScript;
      });

      devShells = forEachSystem (system:
        let
          pkgs = import nixpkgs {
            overlays = [ overlays ];
            inherit system;
            config.allowUnfree = true;
          };
        in {
          default = devenv.lib.mkShell {
            inherit inputs pkgs;
            modules = [ ./devenv.nix ];
          };
        });
    };
}
