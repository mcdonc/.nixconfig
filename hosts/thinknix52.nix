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
    ./roles/steam.nix
    ./roles/davinci-resolve/studio.nix
#    ./roles/vmount.nix  # no steam when this is enabled, but nec for dvresolve
#    ./roles/dnsovertls/resolvedonly.nix
    ./roles/backupsource
    ../common.nix
  ];

  system.stateVersion = "22.05";

  # per-host settings
  networking.hostId = "e1e4a33b";
  networking.hostName = "thinknix52";

  hardware.nvidia.prime.offload.enable = lib.mkForce
    (!config.hardware.nvidia.prime.sync.enable);
  hardware.nvidia.prime.sync.enable = lib.mkForce false;

  # silence ACPI "errors" at boot shown before NixOS stage 1 output (default
  # is 4)
  boot.consoleLogLevel = 3;

}

