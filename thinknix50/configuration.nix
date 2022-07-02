{ config, pkgs, lib, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../common/configuration.nix
  ];
  networking.hostId = "f416c9cd";
  networking.hostName = "thinknix50";

  # override optimus default offload mode to deal with external monitor
  hardware.nvidia.prime.offload.enable = lib.mkForce false;
  hardware.nvidia.prime.sync.enable = true;
}


