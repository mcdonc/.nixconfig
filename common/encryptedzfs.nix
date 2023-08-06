{ ... }:

{
  # Use GRUB, assume UEFI
  boot.loader.grub.enable = true;
  boot.loader.grub.device = "nodev";
  boot.loader.grub.devices = [ "nodev" ];
  boot.loader.grub.efiInstallAsRemovable = true;
  boot.loader.grub.efiSupport = true;
  boot.loader.grub.splashImage = ./grub/alwaysnix.png;
  boot.loader.grub.splashMode = "stretch"; # "normal"
  boot.loader.grub.useOSProber = true;
  boot.loader.timeout = 60;
  boot.kernelModules = [ "snd-seq" "snd-rawmidi" ];
  # copyKernels: "Using NixOS on a ZFS root file system might result in the
  # boot error external pointer tables not supported when the number of
  # hardlinks in the nix store gets very high.
  boot.loader.grub.copyKernels = true;
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
