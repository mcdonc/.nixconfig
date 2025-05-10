{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  inputs.home-manager.url = "github:nix-community/home-manager";

  outputs = { self, nixpkgs, home-manager, ... }:
    let
      system = "x86_64-linux";
    in
    rec {
      apps = {
        x86_64-linux.default = {
          type = "app";
          program =
            let
              pkgs = import nixpkgs { system = "x86_64-linux"; };
              script_text = ''
                read -n 1
                QEMU_KERNEL_PARAMS=console=ttyS0 \
                  ${nixosConfigurations.nixos.config.system.build.vm}/bin/run-nixos-vm -nographic'';
              script = builtins.trace script_text pkgs.writeShellScript "wuddevz" script_text;
            in
              "${script}";
        };
      };
      nixosConfigurations = {
        nixos = nixpkgs.lib.nixosSystem {
          inherit system;
          modules = [
            home-manager.nixosModules.home-manager
            ./configuration.nix
          ];
        };
      };
    };
}
