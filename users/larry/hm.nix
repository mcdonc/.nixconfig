{ config, pkgs, home-manager, ... }:

{
  imports = [ ../hm-shared.nix ];

  programs.git = {
    enable = true;
    userName = "Larry";
    userEmail = "larry@agendaless.com";
  };

}
