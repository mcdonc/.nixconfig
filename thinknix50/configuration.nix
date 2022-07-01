{ config, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../common/configuration.nix
  ];
  networking.hostId = "7fb61f8f";
  networking.hostName = "thinknix50";
}


