{ config, pkgs, lib, ... }:

{
  imports = [
    ../common/pseries.nix
    ../common/encryptedzfs.nix
    ../common/configuration.nix
    #    ../common/rc505.nix
    ../common/oldnvidia.nix
  ];

  # override optimus default offload mode to deal with external monitor
  #hardware.nvidia.prime.offload.enable = false;
  #hardware.nvidia.prime.sync.enable = true;

  # silence ACPI "errors" at boot shown before NixOS stage 1 output (default
  # is 4)
  boot.consoleLogLevel = 3;

  # per-host settings
  networking.hostId = "e1e4a33b";
  networking.hostName = "thinknix52";

  # why must I do this?  I have no idea.  But if I don't, swnix pauses then "fails"
  # (really just prints an error) when it switches configurations.
  systemd.services.NetworkManager-wait-online.enable = false;
}

