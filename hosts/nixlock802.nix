{ pkgs, inputs, ... }:

{
  imports = [
    inputs.nixos-generators.nixosModules.all-formats
    ../users/chrism
    ./roles/minimal
  ];

  boot.initrd.availableKernelModules = [ "xhci_pci" "usbhid" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ ];
  boot.extraModulePackages = [ ];

  networking.hostId = "c923c531";
  networking.hostName = "nixlock802";
  system.stateVersion = "25.05";

  fileSystems."/" =
    { device = "/dev/disk/by-label/NIXOS_SD"; # this is important!
      fsType = "ext4";
      options = [ "noatime" ];
    };

  nixpkgs.hostPlatform = "aarch64-linux";

  # Use the extlinux boot loader. (NixOS wants to enable GRUB by default)
  boot.loader.grub.enable = false;
  # Enables the generation of /boot/extlinux/extlinux.conf
  boot.loader.generic-extlinux-compatible.enable = true;
    
  # networking config. important for ssh!
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
  
}
