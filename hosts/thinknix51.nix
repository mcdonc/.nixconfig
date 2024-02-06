{ config, pkgs, lib, nixos-hardware, ... }:

{
  imports = [
    "${nixos-hardware}/lenovo/thinkpad/p51"
    "${nixos-hardware}/common/pc/ssd"
    ./profiles/pseries.nix
    ./profiles/encryptedzfs.nix
    ./profiles/tlp.nix
    ./profiles/macos-ventura.nix
    ../common.nix
  ];
  system.stateVersion = "22.05";

  networking.hostId = "83540bcc";
  networking.hostName = "thinknix51";

  #hardware.nvidia.prime.offload.enable = false;
  #hardware.nvidia.prime.sync.enable = lib.mkForce true;

  # silence ACPI "errors" at boot shown before NixOS stage 1 output
  # (default is 4)
  boot.consoleLogLevel = 3;

}
