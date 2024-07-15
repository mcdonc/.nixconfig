{ config, pkgs, lib, nixos-hardware, options, ... }:

{
  imports = [
    ../users/chrism
    ./roles/intel.nix
    "${nixos-hardware}/common/pc/ssd"
    ./roles/encryptedzfs.nix
    ./roles/dnsovertls/resolvedonly.nix
    ../common.nix
  ];

  system.stateVersion = "24.05";

  networking.hostId = "90ca4330";
  networking.hostName = "keithmoon";

  boot.initrd.availableKernelModules = [
    "ahci" "xhci_pci" "ehci_pci" "megaraid_sas" "usb_storage" "usbhid"
    "sd_mod"
  ];
  boot.initrd.kernelModules = [ ];
  boot.extraModulePackages = [ ];

  fileSystems."/nix" =
    { device = "NIXROOT/nix";
      fsType = "zfs";
    };

  # 32 GB max ARC cache
  boot.kernelParams = [ "zfs.zfs_arc_max=34359738368" ];

}
