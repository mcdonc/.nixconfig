{ pkgs, lib, inputs, system, ... }:
{
  imports = [
    ./home.nix
  ];

  homebrew = {
    enable = true;
    casks = [
      "google-chrome"
      "firefox"
      "bitwarden"
      "iterm2"
    ];
#    onActivation.cleanup = "zap";
    onActivation.autoUpdate = true;
    onActivation.upgrade = true;
  };

  nix-homebrew.user = "chrism";

  environment.systemPackages = [
    pkgs.vim
    pkgs.speedtest-cli
    pkgs.tmux
    pkgs.nmap
    pkgs.inetutils # for telnet
    pkgs.minicom
    pkgs.netcat
  ];

  system.defaults = {
    dock.autohide = true;
    loginwindow.GuestEnabled = false;
    NSGlobalDomain.AppleInterfaceStyle = "Dark";
    NSGlobalDomain.KeyRepeat = 2;
#    NSGlobalDomain.InitialKeyRepeat = 2; 
    NSGlobalDomain."com.apple.swipescrolldirection" = false;
  };

  # Auto upgrade nix package and the daemon service.
  services.nix-daemon.enable = true;
  # nix.package = pkgs.nix;

  # Necessary for using flakes on this system.
  nix.settings.experimental-features = "nix-command flakes";
  nix.settings.trusted-users = [ "root" "@wheel" ];

  # Create /etc/zshrc that loads the nix-darwin environment.
  programs.zsh.enable = true;
  # avoid "zsh compinit: insecure directories and files, run compaudit for list.
  programs.zsh.enableCompletion = false;

  # Set Git commit hash for darwin-version.
  system.configurationRevision =
    inputs.self.rev or inputs.self.dirtyRev or null;

  # Used for backwards compatibility, please read the changelog before changing.
  # $ darwin-rebuild changelog
  system.stateVersion = 5;

  # The platform the configuration will be used on.
  nixpkgs.hostPlatform = system;

}
