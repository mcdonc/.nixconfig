{ ... }:

{
  boot.supportedFilesystems = [ "zfs" ];
  boot.zfs.requestEncryptionCredentials = true;

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
