{ lib, pkgs, inputs, system, ... }:

{
  imports = [
    inputs.nixos-generators.nixosModules.all-formats
    ../users/chrism
    ./roles/hosted
  ];

  networking.hostId = "bd246190";
  networking.hostName = "hosted";
  system.stateVersion = "25.05";

}
