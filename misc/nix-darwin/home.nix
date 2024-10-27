{ config, pkgs, lib, ...}:
let
  shellAliases = {
    # dont display lines > 200 chars long
    sgrep = "${pkgs.ripgrep}/bin/rg -M 200 --hidden";
    ls = "ls --color=auto";
    diff = "${pkgs.colordiff}/bin/colordiff";
    swnix = "darwin-rebuild switch --flake ~/.nixconfig/misc/nix-darwin";
    swhome = "home-manager switch -f ~/.nixconfig/misc/nix-darwin/home.nix";
    edit = "emacsclient -n -c";
  };

  sessionVariables = {
    MFA_DEVICE = "Bitwarden";
    CLICOLOR="1";
    LSCOLORS="GxFxCxDxBxegedabagaced";
  };

  zshDotDir = ".config/zsh";
  homedir = "/Users/chrism";
in

{
  home.username = "chrism";
  home.homeDirectory = homedir;
  home.stateVersion = "24.05";
  fonts.fontconfig.enable = true;
  home.packages = with pkgs; [
    bat
    nixpkgs-fmt # unnamed dependency of emacs
    fd # fd is an unnamed dependency of fzf
    pkgs.nerdfonts
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
  home.file.".p10k.zsh" = {
    source = ./.p10k.zsh;
    executable = true;
  };

  home.file.".p10k-theme.zsh" = {
    source = "${pkgs.zsh-powerlevel10k}/share/zsh-powerlevel10k/powerlevel10k.zsh-theme";
    executable = true;
  };

  # services.emacs = {
  #   enable = true;
  #   startWithUserSession = "graphical";
  # };

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
        src = "${pkgs.zsh-fast-syntax-highlighting}/share/zsh/site-functions";
      }
    ];
  };

  launchd.agents.emacs = {
    enable = true;
    config = {
      ProgramArguments = ["bash" "-c" "/etc/profiles/per-user/chrism/bin/emacs" "--daemon"];
#      KeepAlive = true;
      RunAtLoad = true;
      #UserName = "chrism";
      #ProcessType = "Interactive";
      StandardOutPath = "${homedir}/emacs.out.log";
      StandardErrorPath = "${homedir}/emacs.err.log";
    };
  };

  programs.ssh = {
    enable = true;
    addKeysToAgent = "yes";
    matchBlocks = {
      "lock802" = {
        user = "pi";
        forwardAgent = true;
      };
      "*" = {
        extraOptions = {
          UseKeychain = "yes";
          IdentityFile = "${homedir}/.ssh/id_ed25519";
        };
      };
    };
  };
}
