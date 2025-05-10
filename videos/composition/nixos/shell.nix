  # shell.nix
  { config, lib, pkgs, ... }:
  {
    environment.shellInit = lib.mkAfter ''export MYVAR="from shell.nix"'';
  }
