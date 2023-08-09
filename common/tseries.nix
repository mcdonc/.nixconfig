{ config, lib, pkgs, modulesPath, ... }:

{

  boot.initrd.availableKernelModules =
    [ "ehci_pci" "ahci" "usb_storage" "sd_mod" "sdhci_pci" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-intel" ];
  boot.extraModulePackages = [ ];

}
