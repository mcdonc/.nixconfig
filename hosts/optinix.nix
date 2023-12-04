{ config, pkgs, lib, nixos-hardware, ... }:

{
  imports = [
    "${nixos-hardware}/common/cpu/intel"
    "${nixos-hardware}/common/pc/ssd"
    ./profiles/encryptedzfs.nix
    ./profiles/dnsovertls/resolvedonly.nix
    ./profiles/speedtest
    ../common.nix
  ];

  powerManagement.cpuFreqGovernor = "performance";

  boot.initrd.availableKernelModules =
    [ "xhci_pci" "ahci" "nvme" "usb_storage" "usbhid" "sd_mod" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-intel" ];
  boot.extraModulePackages = [ ];

  # 500MB max ARC cache
  boot.kernelParams = lib.mkForce [ "zfs.zfs_arc_max=536870912" ];

  fileSystems."/nix" = {
    device = "NIXROOT/nix";
    fsType = "zfs";
  };

  swapDevices = [{ device = "/dev/zvol/NIXROOT/swap"; }];
  system.stateVersion = "23.11";

  networking.hostId = "0a2c6440";
  networking.hostName = "optinix";

}

