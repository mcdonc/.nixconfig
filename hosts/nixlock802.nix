{ pkgs, lib, inputs, ... }:

{
  imports = [
    inputs.nixos-generators.nixosModules.all-formats
    "${inputs.nixos-hardware}/raspberry-pi/4"
    ../users/chrism
    ./roles/minimal
    ./roles/lock802/doorclient.nix
  ];

  services.doorclient.enable = false;
  services.doorclient.clientidentity = "nixlock802";

  hardware.enableAllFirmware = true;
  hardware.firmware = [ pkgs.raspberrypiWirelessFirmware ];

  boot.initrd.availableKernelModules = [ "xhci_pci" "usbhid" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ ];
  boot.extraModulePackages = [ ];

  # Use the extlinux boot loader. (NixOS wants to enable GRUB by default)
  boot.loader.grub.enable = false;
  # Enables the generation of /boot/extlinux/extlinux.conf
  boot.loader.generic-extlinux-compatible.enable = true;

  fileSystems."/" =
    { device = "/dev/disk/by-label/NIXOS_SD"; # this is important!
      fsType = "ext4";
      options = [ "noatime" ];
    };

  system.stateVersion = "25.05";

  nixpkgs.hostPlatform = "aarch64-linux";

  networking.hostId = "c923c531";
  networking.hostName = "nixlock802";
  networking.enableIPv6 = false;
  networking.firewall.enable = lib.mkForce false;
  networking.networkmanager.enable = lib.mkForce true;

  # networkmanager try connect
  # sudo nmcli device wifi connect "ssid" password "password"

  # to use wpa_supplicant, disable networkmanager and add this (routing
  # doesnt work on wifi)

  #networking.wireless.enable = true;
  #networking.wireless.secretsFile = "/var/lib/secrets/wifi";
  #networking.wireless.networks.haircut.pskRaw = "ext:psk";
  #networking.wireless.networks.ytvid-rpi.pskRaw = "18a90748cff3ae6006b78dc2b4a65be47f7e8eb22c46388b636314b535486dcb";

  # "wpa_passphrase ssid passphrase" creates a psk
  # "iwconfig" shows connected ssids

  #networking = {
  #  interfaces.end0 = {
  #    ipv4.addresses = [{
  #      address = "192.168.1.185";
  #      prefixLength = 24;
  #    }];
  #  };
  #  defaultGateway = {
  #    address = "192.168.1.1";
  #    interface = "end0";
  #  };
  #  nameservers = [
  #    "192.168.1.1"
  #  ];
  #};

  # end wpa_supplicant

  environment.systemPackages = [
    pkgs.usbutils # lsusb
    pkgs.pciutils # lsusb
    pkgs.wirelesstools # iwconfig
    pkgs.wpa_supplicant # in case i decide to use it
  ];

}
