{ pkgs, lib, inputs, ... }:
let
  zshDotDir = ".config/zsh";
in
{
  # List packages installed in system profile. To search by name, run:
  # $ nix-env -qaP | grep wget
  environment.systemPackages = [
    pkgs.vim
    #pkgs.emacs
  ];

  # Auto upgrade nix package and the daemon service.
  services.nix-daemon.enable = true;
  # nix.package = pkgs.nix;

  # Necessary for using flakes on this system.
  nix.settings.experimental-features = "nix-command flakes";

  # Create /etc/zshrc that loads the nix-darwin environment.
  programs.zsh.enable = true;  # default shell on catalina
  programs.zsh.enableCompletion = false;
  programs.zsh.interactiveShellInit = ''
    # On slow systems, checking the cached .zcompdump file to see if it must
    # be regenerated adds a noticable delay to zsh startup.  This little
    # hack restricts it to once a day.  It should be pasted into your own
    # completion file.
    #
    # The globbing is a little complicated here:
    # - '#q' is an explicit glob qualifier that makes globbing work within
    #   zsh's [[ ]] construct.
    # - 'N' makes the glob pattern evaluate to nothing when it doesn't match
    #   (rather than throw a globbing error)
    # - '.' matches "regular files"
    # - 'mh+24' matches files (or directories or whatever) that are older
    #   than 24 hours.
    setopt extended_glob
    autoload -Uz compinit
    export ZDOTDIR=~/${zshDotDir}
    if [[ -n ~/${zshDotDir}/.zcompdump(#qN.mh+24) ]]; then
      compinit;
    else
      compinit -C;
    fi;
    alias swnix="darwin-rebuild switch --flake ~/.nixconfig/misc/nix-darwin; home-manager switch -f ~/.nixconfig/misc/nix-darwin/home.nix";
    alias ls="ls --color"
  '';
  # programs.fish.enable = true;

  # Set Git commit hash for darwin-version.
  system.configurationRevision = inputs.self.rev or inputs.self.dirtyRev or null;

  # Used for backwards compatibility, please read the changelog before changing.
  # $ darwin-rebuild changelog
  system.stateVersion = 5;

  # The platform the configuration will be used on.
  nixpkgs.hostPlatform = "x86_64-darwin";
}
