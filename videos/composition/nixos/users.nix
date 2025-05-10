  # users.nix
  { config, lib, pkgs, ... }:
  {
    users.users.chrism = {
      initialPassword = "123";
      isNormalUser = true;
      extraGroups = [ "wheel" ];
    };
  }
