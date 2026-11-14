args@{ config, pkgs, ... }:

{
  # not good enough to just add ../home.nix to imports, must eagerly import,
  # or config.jawns can't be found
  imports = [ (import ../home.nix args) ];

  home.stateVersion = "22.05";

  programs.git = {
    enable = true;
    signing.format = "openpgp";
    # XXX26.11 userName/userEmail/extraConfig all removed; use settings
    settings = {
      user = {
        name = "Larry";
        email = "larry@agendaless.com";
      };
      pull.rebase = "true";
      diff.guitool = "meld";
      difftool.meld.path = "${pkgs.meld}/bin/meld";
      difftool.prompt = "false";
      merge.tool = "meld";
      mergetool.meld.path = "${pkgs.meld}/bin/meld";
      safe.directory = [ "/etc/nixos" ];
    };
  };

}
