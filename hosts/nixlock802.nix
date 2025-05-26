{ pkgs, lib, inputs, ... }:

{
  imports = [
    inputs.nixos-generators.nixosModules.all-formats
    "${inputs.nixos-hardware}/raspberry-pi/4"
    ../users/chrism
    ./roles/minimal
  ];

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
  networking.networkmanager.enable = lib.mkForce false;
  networking.wireless.secretsFile = "/var/lib/secrets/wifi";
  networking.wireless.enable = true;
  networking.wireless.networks.haircut.pskRaw = "ext:psk";

  networking = {
    interfaces.end0 = {
      ipv4.addresses = [{
        address = "192.168.1.185";
        prefixLength = 24;
      }];
    };
    defaultGateway = {
      address = "192.168.1.1"; # or whichever IP your router is
      interface = "end0";
    };
    nameservers = [
      "192.168.1.1" # or whichever DNS server you want to use
    ];
  };

  environment.systemPackages = [
    pkgs.usbutils # lsusb
    pkgs.pciutils # lsusb
    pkgs.wirelesstools # iwconfig
    pkgs.wpa_supplicant
  ];

}
