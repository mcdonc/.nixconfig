{ config, pkgs, lib, ...}:

{
  home.username = "chrism";
  home.homeDirectory = "/Users/chrism";
  home.stateVersion = "24.05";
  home.packages = with pkgs; [
    bat
    nixpkgs-fmt # unnamed dependency of emacs
  ];
  programs.dircolors.enable = true;
  programs.emacs.enable = true;
  programs.emacs.extraPackages = epkgs: [
    epkgs.nix-mode
    epkgs.nixpkgs-fmt
    epkgs.flycheck
    epkgs.json-mode
    epkgs.python-mode
    epkgs.auto-complete
    epkgs.web-mode
    epkgs.smart-tabs-mode
    epkgs.whitespace-cleanup-mode
    epkgs.flycheck-pyflakes
    epkgs.flycheck-pos-tip
    epkgs.nord-theme
    epkgs.nordless-theme
    epkgs.vscode-dark-plus-theme
    epkgs.doom-modeline
    epkgs.all-the-icons
    epkgs.all-the-icons-dired
    epkgs.magit
    epkgs.markdown-mode
    epkgs.markdown-preview-mode
    epkgs.gptel
    pkgs.emacs-all-the-icons-fonts
    epkgs.yaml-mode
    epkgs.multiple-cursors
    epkgs.dts-mode
    epkgs.rust-mode
    epkgs.nickel-mode
  ];

  home.file.".emacs.d" = {
    source = ./.emacs.d;
    recursive = true;
  };

  # services.emacs = {
  #   enable = true;
  #   startWithUserSession = "graphical";
  # };

}
