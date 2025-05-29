{ pkgs, lib, inputs, pkgs-gpio, ... }:
{
  # used under nixos-generators

  imports = [
    "${inputs.nixos-hardware}/raspberry-pi/4"
    ./rpigpio.nix
  ];

  services.zram-generator = {
    enable = true;
    settings.zram0 = {
      compression-algorithm = "zstd";
      zram-size = "ram * 2";
    };
  };

  hardware.enableAllFirmware = true;
  hardware.firmware = [ pkgs.raspberrypiWirelessFirmware ];
  hardware = {
    raspberry-pi."4" = {
      apply-overlays-dtmerge.enable = true;
      fkms-3d.enable = true; # rudolf
      # below is broken
      #audio.enable = true;
      gpio.enable = true;
    };
    deviceTree = {
      enable = true;
      filter = lib.mkForce "*rpi-4-*.dtb"; # seems required to get wlan0?
    };
  };

  # this may not really be required (i think nixos-hardware does this already)
  boot.kernelPackages = pkgs.linuxPackages_rpi4;

  nixpkgs.hostPlatform = "aarch64-linux";

  environment.systemPackages = [
    pkgs.libraspberrypi
    pkgs.raspberrypi-eeprom
  ];

  # Use the extlinux boot loader. (NixOS wants to enable GRUB by default)
  boot.loader.grub.enable = false;
  # Enables the generation of /boot/extlinux/extlinux.conf
  boot.loader.generic-extlinux-compatible.enable = true;

  fileSystems."/" =
    { device = "/dev/disk/by-label/NIXOS_SD"; # this is important!
      fsType = "ext4";
      options = [ "noatime" ];
    };

}
