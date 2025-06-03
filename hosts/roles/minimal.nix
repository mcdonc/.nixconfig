{ config, pkgs, inputs, ... }:

{

  jawns.isworkstation = false;

  time.timeZone = "America/New_York";

  imports = [
    ./shared.nix
    ./packages.nix
  ];

  services.locate.enable = false;

}
