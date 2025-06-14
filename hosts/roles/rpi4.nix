{
  pkgs,
  lib,
  inputs,
  config,
  ...
}:
{
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
      #audio.enable = true; # broken
      gpio.enable = true;
    };
    deviceTree = {
      enable = true;
      filter = lib.mkForce "*rpi-4-*.dtb"; # seems required to get wlan0?
    };
  };

  # https://github.com/NixOS/nixpkgs/issues/154163, fixes kernel build issue
  #hardware.enableAllHardware = lib.mkForce false;

  # alternative to above:
  nixpkgs.overlays = [
    (final: super: {
      makeModulesClosure =
        x: super.makeModulesClosure (x // { allowMissing = true; });
    })
  ];

  nixpkgs.hostPlatform = "aarch64-linux";

  environment.systemPackages = [
    pkgs.libraspberrypi
    pkgs.raspberrypi-eeprom
  ];

  # Use the extlinux boot loader. (NixOS wants to enable GRUB by default)
  boot.loader.grub.enable = false;
  # Enables the generation of /boot/extlinux/extlinux.conf
  boot.loader.generic-extlinux-compatible.enable = true;

  fileSystems."/" = {
    device = "/dev/disk/by-label/NIXOS_SD"; # this is important!
    fsType = "ext4";
    options = [ "noatime" ];
  };

}
