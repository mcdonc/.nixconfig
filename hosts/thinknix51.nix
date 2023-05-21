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
    ../common/home/larry.nix
  ];
  networking.hostId = "83540bcc";
  networking.hostName = "thinknix51";

  #hardware.nvidia.prime.offload.enable = false;
  #hardware.nvidia.prime.sync.enable = lib.mkForce true;

  # silence ACPI "errors" at boot shown before NixOS stage 1 output (default is 4)
  boot.consoleLogLevel = 3;
  #services.xserver.videoDrivers = [ "nvidiaLegacy460" ];

  # why must I do this?  I have no idea.  But if I don't, swnix pauses then "fails"
  # (really just prints an error) when it switches configurations.
  systemd.services.NetworkManager-wait-online.enable = false;
}
