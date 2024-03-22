args@{ config, pkgs, lib, nixos-hardware, ... }:

{
  imports = [
    ../users/chrism
    ../users/larry
    "${nixos-hardware}/lenovo/thinkpad/p51"
    "${nixos-hardware}/common/pc/ssd"
    ./profiles/pseries.nix
    ./profiles/encryptedzfs.nix
    ./profiles/tlp.nix
    ../common.nix
    (
      import ./profiles/macos-ventura.nix (
        args // { mem = "12G"; cores = 4; enable = false; }
      )
    )
  ];
  system.stateVersion = "22.05";

  networking.hostId = "83540bcc";
  networking.hostName = "thinknix51";

  hardware.nvidia.prime.offload.enable = lib.mkForce true;
  hardware.nvidia.prime.sync.enable = lib.mkForce false;

  # silence ACPI "errors" at boot shown before NixOS stage 1 output
  # (default is 4)
  boot.consoleLogLevel = 3;

}
