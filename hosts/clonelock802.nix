{ pkgs, lib, inputs, pkgs-gpio, config, ... }:

{
  imports = [./lock802.nix];
  networking.hostId = lib.mkForce "f034f642";
  networking.hostName = lib.mkForce "clonelock802";
  services.doorclient.clientidentity = lib.mkForce "clonedoorclient";

  age.secrets."wifi" = {
    file = ../secrets/wifi.age;
    mode = "600";
  };

  networking = {
    interfaces.end0.useDHCP = true;
    interfaces.wlan0.useDHCP = true;
    wireless = {
      secretsFile = config.age.secrets."wifi".path;
      enable = true;
      interfaces = ["wlan0"];
      networks."haircut".pskRaw = "ext:psk";
    };
    networkmanager.enable = lib.mkForce false;
  };

  services.dnsmasq.enable = true;

}
