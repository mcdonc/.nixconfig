{ config, pkgs, lib, nixos-hardware, options, ... }:

{
  imports = [
    #"${nixos-hardware}/lenovo/thinkpad/p51"
    # generated hardware config goes here
    ../encryptedzfs.nix
    ../sessile.nix
    ../common.nix
  ];
  system.stateVersion = "23.05";

  networking.hostId = "eeabbced";
  networking.hostName = "thinkcentre1";

  hardware.nvidia.prime.offload.enable = false;
  hardware.nvidia.prime.sync.enable = lib.mkForce true;

  # silence ACPI "errors" at boot shown before NixOS stage 1 output (default
  # is 4)
  #boot.consoleLogLevel = 3;

  # why must I do this?  I have no idea.  But if I don't, swnix pauses then
  # "fails" (really just prints an error) when it switches configurations.
  #systemd.services.NetworkManager-wait-online.enable = false;

  #services.cachix-agent.enable = true;
}
