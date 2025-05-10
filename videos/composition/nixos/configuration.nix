  # configuration.nix
  { config, lib, pkgs, ... }:
  {
    imports = [ ./shell.nix ./users.nix ];
    boot.loader.systemd-boot.enable = true;
    boot.loader.efi.canTouchEfiVariables = true;
    environment.shellInit = ''export MYVAR="default"'';
  }

