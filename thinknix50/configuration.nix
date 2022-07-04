{ config, pkgs, lib, ... }:

{
  imports = [
    <nixos-hardware-fork/lenovo/thinkpad/p50>
    ../common/pseries.nix
    ../common/p50sleep.nix
    ../common/encryptedzfs.nix
    ../common/configuration.nix
  ];
  networking.hostId = "f416c9cd";
  networking.hostName = "thinknix50";
  networking.useDHCP = lib.mkForce true;

  # override optimus default offload mode to deal with external monitor
  hardware.nvidia.prime.offload.enable = lib.mkForce false;
  hardware.nvidia.prime.sync.enable = true;
}


