{ ... }:

{
  imports = [
    ./grub/efi.nix
  ];

  boot.supportedFilesystems = [ "zfs" ];
  boot.zfs.requestEncryptionCredentials = true;
  # 4 GB max ARC cache
  boot.kernelParams = [ "zfs.zfs_arc_max=4294967296" ];

  services.zfs.autoScrub.enable = true;
  services.zfs.autoScrub.interval = "quarterly";
  services.zfs.trim.enable = true;

  fileSystems."/" = {
    device = "NIXROOT/root";
    fsType = "zfs";
  };

  fileSystems."/home" = {
    device = "NIXROOT/home";
    fsType = "zfs";
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-label/NIXBOOT";
    fsType = "vfat";
  };

  swapDevices = [ ];
}
