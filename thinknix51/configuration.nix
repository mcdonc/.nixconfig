{ config, pkgs, lib, ... }:

let
  hw = fetchTarball
    "https://github.com/NixOS/nixos-hardware/archive/master.tar.gz";
in {
  imports = [
    (import "${hw}/lenovo/thinkpad/p51")
    ../common/pseries.nix
    ../common/encryptedzfs.nix
    ../common/configuration.nix
    ../common/rc505.nix
  ];
  networking.hostId = "83540bcc";
  networking.hostName = "thinknix51";
  networking.useDHCP = lib.mkForce true;

  hardware.nvidia.prime.offload.enable = false;
  hardware.nvidia.prime.sync.enable = lib.mkForce true;

  # silence ACPI "errors" at boot shown before NixOS stage 1 output (default is 4)
  boot.consoleLogLevel = 3;
}
