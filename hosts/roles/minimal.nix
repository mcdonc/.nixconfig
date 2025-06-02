{ config, pkgs, inputs, ... }:

{

  jawns.isworkstation = false;

  imports = [
    ./shared.nix
    ./packages.nix
  ];

  networking.firewall.enable = true;
  networking.firewall.allowedTCPPorts = [ 22 80 443 ];

  time.timeZone = "America/New_York";

  services.locate.enable = false;

}
