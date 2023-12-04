{ config, pkgs, lib, nixos-hardware, ... }:

{
  imports = [
    "${nixos-hardware}/lenovo/thinkpad/p52"
    ./profiles/pseries.nix
    ./profiles/encryptedzfs.nix
    ../common.nix
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

}

