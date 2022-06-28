{ config, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../common/configuration.nix
  ];
  networking.hostId = "83540bcc";
  networking.hostName = "thinknix51";
}


