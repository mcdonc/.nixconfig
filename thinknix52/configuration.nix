{ config, pkgs, lib, ... }:

let
  hwfork = fetchTarball "https://github.com/mcdonc/nixos-hardware/archive/pseries-additions.tar.gz";
in
{
  imports = [
    (import "${hwfork}/lenovo/thinkpad/p52")
    ../common/pseries.nix
    ../common/encryptedzfs.nix
    ../common/configuration.nix
  ];

  # override optimus default offload mode to deal with external monitor
  hardware.nvidia.prime.offload.enable = lib.mkForce false;
  hardware.nvidia.prime.sync.enable = true;

  # fix suspend/resume screen corruption
  hardware.nvidia.powerManagement.enable = true;
  
  networking.hostId = "e1e4a33b";
  networking.hostName = "thinknix52";
  networking.useDHCP = lib.mkForce true;

  # why?  I have no idea.
  systemd.services.NetworkManager-wait-online.enable = false;
}


