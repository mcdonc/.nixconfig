# configuration.nix
{ config, lib, pkgs, ... }:
{
  imports = [ ./demo.nix ];
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
}
