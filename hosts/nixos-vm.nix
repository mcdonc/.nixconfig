{ config, lib, pkgs, modulesPath, ... }:

{
  imports =
    [ (modulesPath + "/profiles/qemu-guest.nix")
    ../common.nix
    ];

  boot.initrd.availableKernelModules = [ "ahci" "xhci_pci" "virtio_pci" "sr_mod" "virtio_blk" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-intel" ];
  boot.extraModulePackages = [ ];

  boot.loader.grub.device = "/dev/vda";
  boot.loader.grub.enable = true;
  boot.loader.timeout = 60;
  #boot.loader.grub.efiInstallAsRemovable = true;
  #boot.loader.grub.efiSupport = true;
  
  fileSystems."/" =
    { device = "/dev/disk/by-uuid/9f6f3554-a000-4f9e-b3b9-844a2a7a8cb0";
      fsType = "ext4";
    };

  swapDevices =
    [ { device = "/dev/disk/by-uuid/6c848ad1-2f09-467c-8746-c415c6b1b696"; }
    ];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  networking.hostId = "fd244a99";
  networking.hostName = "nixos";
  system.stateVersion = "23.11";

}
