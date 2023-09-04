{ config, pkgs, lib, nixos-hardware, options, ... }:

{
  imports = [
    #"${nixos-hardware}/lenovo/thinkpad/p51"
    ../encryptedzfs.nix
    ../sessile.nix
    ../common.nix
  ];
  system.stateVersion = "23.05";

  networking.hostId = "eeabbced";
  networking.hostName = "thinkcentre1";

  # silence ACPI "errors" at boot shown before NixOS stage 1 output (default
  # is 4)
  #boot.consoleLogLevel = 3;

  # why must I do this?  I have no idea.  But if I don't, swnix pauses then
  # "fails" (really just prints an error) when it switches configurations.
  #systemd.services.NetworkManager-wait-online.enable = false;

  #services.cachix-agent.enable = true;

  boot.initrd.availableKernelModules = [ "xhci_pci" "ehci_pci" "ahci" "usb_storage" "usbhid" "sd_mod" "sr_mod" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-intel" ];
  boot.extraModulePackages = [ ];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;

  hardware = {
    nvidia = {
      modesetting.enable = true;
      powerManagement.enable = true;
      open = false;
      nvidiaSettings = false;
    };

    # is this too much?  It's convenient for Steam.
    opengl = {
      enable = true;
      driSupport = lib.mkDefault true;
      driSupport32Bit = lib.mkDefault true;
    };
  };

  # required to make wireless work
  hardware.enableAllFirmware = lib.mkDefault true;
}
