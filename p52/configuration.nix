{ config, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../common/configuration.nix
  ];
  networking.hostId = "e1e4a33b";
  networking.hostName = "thinknix52";
}


