{ pkgs, lib, inputs, system, config, username, ... }:
let
  shellAliases = {
    # dont display lines > 200 chars long
    sgrep = "${pkgs.ripgrep}/bin/rg -M 200 --hidden";
    ls = "ls --color=auto";
    diff = "${pkgs.colordiff}/bin/colordiff";
    swnix = "darwin-rebuild switch --flake ~/.nixconfig/darwin";
    edit = "${emacspkg}/bin/emacsclient -n -c";
    restartemacs =
      "launchctl kickstart -k gui/$UID/org.nix-community.home.emacs";
  };

  sessionVariables = {
    CLICOLOR = "1";
    # LSCOLORS="GxFxCxDxBxegedabagaced";
    EDITOR = "vi";
    FXDEV_USE_ZSH="1";
  };

  zshDotDir = ".config/zsh";
  homedir = "/Users/${username}";
  emacspkg =
    config.home-manager.users."${username}".programs.emacs.finalPackage;
  emacsdaemon = pkgs.writeShellScript "emacsdaemon" ''
    exec ${emacspkg}/bin/emacs --fg-daemon
  '';
  zshtheme =
    "${pkgs.zsh-powerlevel10k}/share/zsh-powerlevel10k/powerlevel10k.zsh-theme";
in
{
  homebrew = {
    enable = true;
    casks = [
      #"google-chrome"
      #"firefox"
      "bitwarden"
      "iterm2"
      #"displayplacer"
      #"betterdisplay"
    ];
    #onActivation.cleanup = "zap";
    onActivation.autoUpdate = true;
    onActivation.upgrade = true;
  };

  nix-homebrew.user = username;

  fonts.packages = [
    pkgs.nerd-fonts.ubuntu-mono
  ];

  environment.systemPackages = [
    pkgs.vim
    pkgs.speedtest-cli
    pkgs.tmux
    pkgs.nmap
    pkgs.inetutils # for telnet
    pkgs.minicom
    pkgs.netcat
    pkgs.htop
  ];

  system.defaults = {
    # dock.autohide = true;
    loginwindow.GuestEnabled = false;
    NSGlobalDomain.AppleInterfaceStyle = "Dark";
    NSGlobalDomain.KeyRepeat = 2;
    # NSGlobalDomain.InitialKeyRepeat = 2;
    NSGlobalDomain."com.apple.swipescrolldirection" = false;
  };

  system.keyboard.enableKeyMapping = true;
  system.keyboard.remapCapsLockToControl = true;

  # Auto upgrade nix package and the daemon service.
  services.nix-daemon.enable = true;

  # Necessary for using flakes on this system.
  nix.settings.experimental-features = "nix-command flakes";
  nix.settings.trusted-users = [ "root" "@wheel" username ];

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

  # Allow unfree software.
  nixpkgs.config.allowUnfree = true;

  users.users."${username}" = {
    name = username;
    home = homedir;
    openssh = {
      authorizedKeys.keys = [
        "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCnLD+dQsKPhCV3eY0lMUP4fDrECI1Boe6PbnSHY+eqRpkA/Nd5okdyXvynWETivWsKdDRlT3gIVgEHqEv8s4lzxyZx9G2fAgQVVpBLk18G9wkH0ARJcJ0+RStXLy9mwYl8Bw8J6kl1+t0FE9Aa9RNtqKzpPCNJ1Uzg2VxeNIdUXawh77kIPk/6sKyT/QTNb5ruHBcd9WYyusUcOSavC9rZpfEIFF6ZhXv2FFklAwn4ggWzYzzSLJlMHzsCGmkKmTdwKijkGFR5JQ3UVY64r3SSYw09RY1TYN/vQFqTDw8RoGZVTeJ6Er/F/4xiVBlzMvxtBxkjJA9HLd8djzSKs8yf amnesia@amnesia"
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOLXUsGqUIEMfcXoIiiItmGNqOucJjx5D6ZEE3KgLKYV ednesia"
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFDEWQSmS/BXw7/KXJRaS73VkNxA9K3Qt0+t+onQwznA cpmcdono"
      ];
    };
  };

  home-manager = {
    users."${username}" = {
      home.username = username;
      home.homeDirectory = homedir;
      home.stateVersion = "24.05";

      home.packages = with pkgs; [
        bat
        nixpkgs-fmt # unnamed dependency of emacs
        fd # fd is an unnamed dependency of fzf
      ];

      programs.git = {
        enable = true;
        userName = "Chris McDonough";
        userEmail = "chrism@plope.com";
        extraConfig = {
          pull.rebase = "true";
          diff.guitool = "meld";
          difftool.meld.path = "${pkgs.meld}/bin/meld";
          difftool.prompt = "false";
          merge.tool = "meld";
          mergetool.meld.path = "${pkgs.meld}/bin/meld";
        };
      };

      # in case someone installs coreutils
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
      home.file.".p10k.zsh" = {
        source = ../users/.p10k-fornax.zsh;
        executable = true;
      };

      home.file.".p10k-theme.zsh" = {
        source = zshtheme;
        executable = true;
      };

      # i later found out that this might be avoided by using
      # nix-darwin.services.emacs, but it works
      launchd.agents.emacs = {
        enable = true;
        config = {
          Program = "${emacsdaemon}";
          KeepAlive = true;
          RunAtLoad = true;
          ProcessType = "Interactive";
          StandardOutPath = "${homedir}/.emacs.out.log";
          StandardErrorPath = "${homedir}/.emacs.err.log";
          EnvironmentVariables = { "PATH" = config.environment.systemPath; };
        };
      };

      programs.bash = {
        enable = true;
        shellAliases = shellAliases;
        sessionVariables = sessionVariables;
        enableCompletion = true;
      };

      programs.fzf.enable = true;
      programs.fzf.enableZshIntegration = true;

      programs.zsh = {
        enable = true;
        shellAliases = shellAliases;
        sessionVariables = sessionVariables;
        enableCompletion = true;

        dotDir = zshDotDir;
        autosuggestion.enable = true;

        # speed up zsh start time, see
        # https://medium.com/@dannysmith/little-thing-2-speeding-up-zsh-f1860390f92
        # (needs extended_glob)
        completionInit = ''
          # On slow systems, checking the cached .zcompdump file to see if it
          # must be regenerated adds a noticable delay to zsh startup.  This
          # little hack restricts it to once a day.  It should be pasted into
          # your own completion file.
          #
          # The globbing is a little complicated here:
          # - '#q' is an explicit glob qualifier that makes globbing work within
          #   zsh's [[ ]] construct.
          # - 'N' makes the glob pattern evaluate to nothing when it doesn't
          #   match (rather than throw a globbing error)
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
        '';

        #initExtraFirst = ''
        #  zmodload zsh/zprof
        #'';

        initExtra = ''
          # be more bashy
          setopt interactive_comments bashautolist nobeep nomenucomplete \
                 noautolist extended_glob

          source ~/.p10k.zsh
          source ~/.p10k-theme.zsh

          ## Keybindings section
          bindkey -e
          bindkey '^I' fzf-completion                         # anything**<TAB>
          bindkey '^[[7~' beginning-of-line                   # Home key
          bindkey '^[[H' beginning-of-line                    # Home key
          # [Home] - Go to beginning of line
          if [[ "''${terminfo[khome]}" != "" ]]; then
          bindkey "''${terminfo[khome]}" beginning-of-line
          fi
          bindkey '^[[8~' end-of-line                         # End key
          bindkey '^[[F' end-of-line                          # End key
          # [End] - Go to end of line
          if [[ "''${terminfo[kend]}" != "" ]]; then
          bindkey "''${terminfo[kend]}" end-of-line
          fi
          bindkey '^[[2~' overwrite-mode                      # Insert key
          bindkey '^[[3~' delete-char                         # Delete key
          bindkey '^[[C'  forward-char                        # Right key
          bindkey '^[[D'  backward-char                       # Left key
          bindkey '^[[5~' history-beginning-search-backward   # Page up key
          bindkey '^[[6~' history-beginning-search-forward    # Page down key
          # Navigate words with ctrl+arrow keys
          bindkey '^[Oc' forward-word
          bindkey '^[Od' backward-word
          bindkey '^[[1;5D' backward-word
          bindkey '^[[1;5C' forward-word
          # delete previous word with ctrl+backspace
          bindkey '^H' backward-kill-word

          findup () {
            # uses zsh extended globbing, https://unix.stackexchange.com/a/64164
            echo (../)#$1(:a)
          }

          #zprof
        '';
        plugins = [
          {
            name = "fast-syntax-highlighting";
            src =
              "${pkgs.zsh-fast-syntax-highlighting}/share/zsh/site-functions";
          }
        ];
      };

      programs.ssh = {
        enable = true;
        addKeysToAgent = "yes";
        matchBlocks = {
          "lock802" = {
            user = "pi";
            forwardAgent = true;
          };
          # Apple ssh extension
          "*" = {
            extraOptions = {
              UseKeychain = "yes";
            };
          };
        };
      };
    };
  };
}
