{ config, pkgs, lib, ... }:

let
  hwfork = fetchTarball
    "https://github.com/mcdonc/nixos-hardware/archive/pseries-additions.tar.gz";
in {
  imports = [
    (import "${hwfork}/lenovo/thinkpad/p51")
    ../common/pseries.nix
    ../common/encryptedzfs.nix
    ../common/configuration.nix
  ];
  networking.hostId = "83540bcc";
  networking.hostName = "thinknix51";
  networking.useDHCP = lib.mkForce true;

  hardware.nvidia.prime.offload.enable = false;
  hardware.nvidia.prime.sync.enable = lib.mkForce true;

  # silence ACPI "errors" at boot shown before NixOS stage 1 output (default is 4)
  boot.consoleLogLevel = 3;
}
