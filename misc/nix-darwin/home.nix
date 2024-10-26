{ config, pkgs, lib, ...}:

{
  home.username = "chrism";
  home.homeDirectory = "/Users/chrism";
  home.stateVersion = "24.05";
  home.packages = with pkgs; [
    bat
  ];
}
