{ config, pkgs, lib, ... }:

{
  imports = [
    <nixos-hardware-fork/lenovo/thinkpad/p51>
    <nixos-hardware-fork/common/cpu/intel/kaby-lake>
    ../common/pseries.nix
    ../common/p51sleep.nix
    ../common/encryptedzfs.nix
    ../common/configuration.nix
  ];
  networking.hostId = "83540bcc";
  networking.hostName = "thinknix51";
  networking.useDHCP = lib.mkForce true;

  #hardware.nvidia.prime.offload.enable = false;
  #hardware.nvidia.prime.sync.enable = lib.mkForce true;


}
