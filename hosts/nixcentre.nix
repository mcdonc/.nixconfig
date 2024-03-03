{ config, pkgs, lib, nixos-hardware, options, ... }:

{
  imports = [
    "${nixos-hardware}/common/cpu/intel"
    "${nixos-hardware}/common/pc/ssd"
    ./profiles/encryptedzfs.nix
    ./profiles/dnsovertls/resolvedonly.nix
    ./profiles/sessile.nix
    ../common.nix
  ];

  system.stateVersion = "23.11";

  networking.hostId = "849b55f4";
  networking.hostName = "nixcentre";

  powerManagement.cpuFreqGovernor = "performance";
  
  boot.initrd.availableKernelModules =
    [ "xhci_pci" "ehci_pci" "ahci" "usb_storage" "usbhid" "sd_mod" "sr_mod" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-intel" ];
  boot.extraModulePackages = [ ];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";

  # 2GB max ARC cache
  boot.kernelParams = lib.mkForce [ "zfs.zfs_arc_max=2147483648" ];

  fileSystems."/nix" = {
    device = "NIXROOT/nix";
    fsType = "zfs";
  };


}
