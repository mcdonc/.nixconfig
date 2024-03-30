{ config, pkgs, lib, nixos-hardware, ... }:

{
  imports = [
    ../users/chrism
    "${nixos-hardware}/lenovo/thinkpad/p52"
    "${nixos-hardware}/common/pc/ssd"
    ./roles/pseries.nix
    ./roles/encryptedzfs.nix
    ./roles/tlp.nix
    #./roles/sessile.nix
    ./roles/vmount.nix
    ../common.nix
  ];

  system.stateVersion = "22.05";

  # override optimus default offload mode to deal with external monitor
  hardware.nvidia.prime.offload.enable = true;
  hardware.nvidia.prime.sync.enable = false;

  # silence ACPI "errors" at boot shown before NixOS stage 1 output (default
  # is 4)
  boot.consoleLogLevel = 3;

  # per-host settings
  networking.hostId = "e1e4a33b";
  networking.hostName = "thinknix52";

}

