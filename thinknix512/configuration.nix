{ config, pkgs, lib, ... }:

let
  hwfork = fetchTarball "https://github.com/mcdonc/nixos-hardware/archive/pseries-additions.tar.gz";
in
{
  imports = [
    (import "${hwfork}/lenovo/thinkpad/p51")
    ../common/pseries.nix
    ../common/encryptedzfs.nix
    ../common/configuration.nix
  ];
  networking.hostId = "deadbeef";
  networking.hostName = "thinknix512";
  networking.useDHCP = lib.mkForce true;

  hardware.nvidia.prime.offload.enable = false;
  hardware.nvidia.prime.sync.enable = lib.mkForce true;
  # fix suspend/resume screen corruption in sync mode
  hardware.nvidia.powerManagement.enable = true;
}


