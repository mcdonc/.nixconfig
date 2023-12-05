{ config, pkgs, lib, nixos-hardware, options, ... }:

{
  imports = [
    "${nixos-hardware}/common/cpu/intel"
    "${nixos-hardware}/common/pc/ssd"
    ./profiles/encryptedzfs.nix
    ./profiles/dnsovertls/resolvedonly.nix
    ./profiles/speedtest
    ./profiles/backupsource
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

  services.sanoid = {
    enable = true;
    #interval = "*:0/1";
    interval = "hourly"; # run this hourly, run syncoid daily to prune ok
    datasets = {
      "NIXROOT/home" = {
        autoprune = true;
        autosnap = true;
        hourly = 0;
        daily = 1;
        weekly = 1;
        monthly = 1;
        yearly = 0;
      };
    };
    extraArgs = [ "--debug" ];
  };
}

