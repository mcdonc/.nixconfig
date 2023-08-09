{ config, pkgs, lib, nixos-hardware, ... }:

{
  imports = [
    "${nixos-hardware}/lenovo/thinkpad/p52"
    ../pseries.nix
    ../encryptedzfs.nix
    ../common.nix
    #    ../rc505.nix
#    ../oldnvidia.nix
  ];

  system.stateVersion = "22.05";

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

