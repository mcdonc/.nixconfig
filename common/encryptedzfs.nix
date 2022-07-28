{ ... }:

{
  boot.supportedFilesystems = [ "zfs" ];
  boot.zfs.requestEncryptionCredentials = true;
  # 4 GB max ARC cache
  boot.kernelParams = [ "zfs.zfs_arc_max=4294967296" ];

  fileSystems."/" =
    { device = "NIXROOT/root";
      fsType = "zfs";
    };

  fileSystems."/boot" =
    { device = "/dev/disk/by-label/NIXBOOT";
      fsType = "vfat";
    };

  fileSystems."/home" =
    { device = "NIXROOT/home";
      fsType = "zfs";
    };

  swapDevices = [ ];
}
