# flake.nix
{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

  outputs = { self, nixpkgs, ... }:
    let
      system = "x86_64-linux";
    in
    {
      nixosConfigurations = {
        barris = nixpkgs.lib.nixosSystem {
          inherit system;
          modules = [
            ./configuration.nix
            {
              networking.hostName = nixpkgs.lib.mkDefault "barris";
            }
          ];
        };
        # luckman = nixpkgs.lib.nixosSystem {
        #   inherit system;
        #   modules = [
        #     ./configuration.nix
        #     {
        #       networking.hostName = nixpkgs.lib.mkDefault "luckman";
        #     }
        #   ];
        # };
        # arctor = nixpkgs.lib.nixosSystem {
        #   inherit system;
        #   modules = [
        #     ./configuration.nix
        #     {
        #       networking.hostName = nixpkgs.lib.mkDefault "arctor";
        #     }
        #   ];
        # };
      };
    };
}
