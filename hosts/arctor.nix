{ lib, pkgs, inputs, system, ... }:

{
  imports = [
    "${inputs.nixpkgs}/nixos/modules/virtualisation/digital-ocean-config.nix"
    inputs.nixos-generators.nixosModules.all-formats
    ../users/chrism
    ../users/tseaver
    ./roles/minimal
  ];

  networking.hostId = "bd246190";
  networking.hostName = "arctor";
  system.stateVersion = "25.05";
  services.cloud-init.enable = true;

}
