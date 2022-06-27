{ config, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../common/configuration.nix
  ];
  networking.hostId = "deadbeef";
  networking.hostName = "thinknix512";
}


