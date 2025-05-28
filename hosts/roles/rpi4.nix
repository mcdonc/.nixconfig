{ pkgs, lib, inputs, pkgs-gpio, ... }:
{
  # used under nixos-generators

  imports = [
    "${inputs.nixos-hardware}/raspberry-pi/4"
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
    };
    deviceTree = {
      enable = true;
      filter = lib.mkForce "*rpi-4-*.dtb"; # seems required to get wlan0?
    };
  };

  # this may not really be required (i think nixos-hardware does this already)
  boot.kernelPackages = pkgs.linuxPackages_rpi4;

  users.groups.gpio = {};

  # the bit that matters to lgpio here is
  # "${pkgs.coreutils}/bin/chgrp gpio /dev/%k && chmod 660 /dev/%k"
  # https://github.com/NixOS/nixpkgs/pull/352308 (me and doron)
  # sudo udevadm test --action=add /dev/gpiochip0
  # import lgpio; lgpio.gpiochip_open(0) should show "1" and not raise
  # an exception

  services.udev.extraRules = ''
    KERNEL=="gpiomem", GROUP="gpio", MODE="0660"
    SUBSYSTEM=="gpio", KERNEL=="gpiochip*", ACTION=="add", PROGRAM="${pkgs.bash}/bin/bash -c '${pkgs.coreutils}/bin/chgrp gpio /dev/%k && chmod 660 /dev/%k && ${pkgs.coreutils}/bin/chgrp -R gpio /sys/class/gpio && ${pkgs.coreutils}/bin/chmod -R g=u /sys/class/gpio'"
    SUBSYSTEM=="gpio", ACTION=="add", PROGRAM="${pkgs.bash}/bin/bash -c '${pkgs.coreutils}/bin/chgrp -R gpio /sys%p && ${pkgs.coreutils}/bin/chmod -R g=u /sys%p'"
  ''; # requires reboot

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
