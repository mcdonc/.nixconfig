{ config, pkgs, lib, ... }:

{
  imports = [
    <nixos-hardware-fork/lenovo/thinkpad/p51>
    ../common/pseries.nix
    ../common/p51sleep.nix
    ../common/encryptedzfs.nix
    ../common/configuration.nix
  ];
  networking.hostId = "deadbeef";
  networking.hostName = "thinknix512";
  networking.useDHCP = lib.mkForce true;

  #hardware.nvidia.prime.offload.enable = false;
  #hardware.nvidia.prime.sync.enable = mkForce true;
}


