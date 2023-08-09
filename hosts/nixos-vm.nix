{ config, pkgs, ... }:

{
  imports =
    [
      ./vm-hardware-config.nix
      ../common.nix
    ];
  
  boot.loader.grub.enable = true;
  boot.loader.grub.device = "/dev/vda";
  boot.loader.grub.useOSProber = true;

  networking.hostName = "nixos";
  networking.networkmanager.enable = true;
  networking.hostId = "deadbeee";

  system.stateVersion = "23.05";

}
