{ config, lib, pkgs, ... }:

{
  imports = [
    <nixos-hardware-fork/lenovo/thinkpad/p52>
    ../common/pseries.nix
    ../common/encryptedzfs.nix
    ../common/configuration.nix
  ];

  # override optimus default offload mode to deal with external monitor
  hardware.nvidia.prime.offload.enable = lib.mkForce false;
  hardware.nvidia.prime.sync.enable = true;

  networking.hostId = "e1e4a33b";
  networking.hostName = "thinknix52";
  networking.useDHCP = lib.mkForce true;

  # why?  I have no idea.
  systemd.services.NetworkManager-wait-online.enable = false;
}


