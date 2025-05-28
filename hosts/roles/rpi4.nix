{ pkgs, lib, inputs, pkgs-gpio, ... }:
{
  # used under nixos-generators

  imports = [
    "${inputs.nixos-hardware}/raspberry-pi/4"
  ];

  hardware.enableAllFirmware = true;
  hardware.firmware = [ pkgs.raspberrypiWirelessFirmware ];
  hardware = {
    raspberry-pi."4" = {
      apply-overlays-dtmerge.enable = true;
      fkms-3d.enable = true; # rudolf
    };
    deviceTree = {
      enable = true;
      filter = lib.mkForce "*rpi-4-*.dtb"; # seems required to get wlan0?
    };
  };

  # this may not really be required (i think nixos-hardware does this already)
  boot.kernelPackages = pkgs.linuxPackages_rpi4;

  users.groups.gpio = {};
  services.udev.extraRules = ''
    KERNEL=="gpiomem", GROUP="gpio", MODE="0660"
    SUBSYSTEM=="gpio", KERNEL=="gpiochip*", ACTION=="add", PROGRAM="${pkgs.bash}/bin/bash -c '${pkgs.coreutils}/bin/chgrp -R gpio /sys/class/gpio && ${pkgs.coreutils}/bin/chmod -R g=u /sys/class/gpio'"
    SUBSYSTEM=="gpio", ACTION=="add", PROGRAM="${pkgs.bash}/bin/bash -c '${pkgs.coreutils}/bin/chgrp -R gpio /sys%p && ${pkgs.coreutils}/bin/chmod -R g=u /sys%p'"
  '';
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
