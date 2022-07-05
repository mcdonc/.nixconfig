{ config, pkgs, lib, ... }:

let
  hwfork = fetchTarball "https://github.com/mcdonc/nixos-hardware/archive/pseries-additions.tar.gz";
in
{
  imports = [
    (import "${hwfork}/lenovo/thinkpad/p51")
    (import "${hwfork}/lenovo/thinkpad/p51/sleep.nix")
    ../common/pseries.nix
    ../common/encryptedzfs.nix
    ../common/configuration.nix
  ];
  networking.hostId = "83540bcc";
  networking.hostName = "thinknix51";
  networking.useDHCP = lib.mkForce true;

  #hardware.nvidia.prime.offload.enable = false;
  #ehardware.nvidia.prime.sync.enable = lib.mkForce true;
}
