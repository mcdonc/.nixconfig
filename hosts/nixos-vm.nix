{ config, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./vm-hardware-config.nix
      ../common/configuration.nix
    ];
  
  system.stateVersion = "23.05"; # Did you read the comment?

  boot.loader.grub.enable = true;
  boot.loader.grub.device = "/dev/vda";
  boot.loader.grub.useOSProber = true;

  networking.hostName = "nixos"; # Define your hostname.
  networking.hostId = "deadbeed";

}
