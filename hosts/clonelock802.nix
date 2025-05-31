{ pkgs, lib, inputs, pkgs-gpio, config, ... }:

{
  imports = [./lock802.nix];
  networking.hostId = lib.mkForce "f034f642";
  networking.hostName = lib.mkForce "clonelock802";
  services.doorclient.clientidentity = lib.mkForce "clonedoorclient";
  services.doorclient.nopage = true;

}
