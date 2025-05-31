{ pkgs, lib, inputs, pkgs-gpio, config, ... }:

{
  imports = [./lock802.nix];
  networking.hostId = lib.mkForce "f034f642";
  networking.hostName = lib.mkForce "clonelock802";
  services.doorclient.clientidentity = lib.mkForce "clonedoorclient";

  networking = {
    useDHCP = true;
    wireless = {
      enable = true;
      interfaces = ["wlan0"];
      # ! Change the following to connect to your own network
      networks = {
        "ytvid-rpi" = { # SSID
          psk = "ytvid-rpi"; # password
        };
      };
    };
  };

  networking.networkmanager.enable = lib.mkForce false;
  services.dnsmasq.enable = true;

}
