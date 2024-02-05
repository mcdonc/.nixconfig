{ config, pkgs, home-manager, ... }:

{
  imports = [ ../hm-shared.nix ];

  home.stateVersion = "22.05";

  programs.git = {
    enable = true;
    userName = "Larry";
    userEmail = "larry@agendaless.com";
    extraConfig = {
      pull.rebase = "true";
      diff.guitool = "meld";
      difftool.meld.path = "${pkgs.meld}/bin/meld";
      difftool.prompt = "false";
      merge.tool = "meld";
      mergetool.meld.path = "${pkgs.meld}/bin/meld";
      safe.directory = ["/etc/nixos"];
    };
  };

}
