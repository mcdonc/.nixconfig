{ pkgs, pkgs-unstable, nixgl-olive, ... }:

let

  nixos-update = pkgs.writeShellScript "nixos-update" ''
    cd /etc/nixos
    git pull
    nix flake update
    sudo nixos-rebuild switch --verbose
  '';

  gterm-change-profile = "xdotool key --clearmodifiers Shift+F10 r";

  ssh-chcolor = pkgs.writeShellScriptBin "ssh-chcolor" ''
    source ${gterm-color-funcs}/bin/gterm-color-funcs
    chcolor 5
    ${pkgs.openssh}/bin/ssh $@
    if [ $? -ne 0 ]; then
       trap 'colorbye' SIGINT
       echo -e "\e[31mSSH exited unexpectedly, hit enter to continue\e[0m"
       read -p ""
    fi
    chcolor 1
  '';

  gterm-color-funcs = pkgs.writeShellScriptBin "gterm-color-funcs" ''
    function chcolor() {
      # emulates right-clicking and selecting a numbered gnome-terminal
      # profile. hide output if it fails.  --clearmodifiers ignores any
      # modifier keys you're physically holding before sending the command
      if [ -n "$GNOME_TERMINAL_SERVICE" ]; then
         ${gterm-change-profile} $1 > /dev/null 2>&1
      fi
    }

    function colorbye () {
       chcolor 1
       exit
    }
  '';

  thumbnail = pkgs.writeShellScript "thumbnail" ''
    # writes to ./thumbnail.png
    # thumbnail eyedrops2.mp4 00:01:07
    ${pkgs.ffmpeg-full}/bin/ffmpeg -y -i "$1" -ss "$2" \
      -vframes 1 thumbnail.png > /dev/null 2>&1
  '';

  defaultpalette = [
    "#171421"
    "#ED1515"
    "#11D116"
    "#FF6D03"
    "#1D99F3"
    "#A347BA"
    "#2AA1B3"
    "#D0CFCC"
    "#5E5C64"
    "#F66151"
    "#33D17A"
    "#E9AD0C"
    "#2A7BDE"
    "#C061CB"
    "#33C7DE"
    "#FFFFFF"
  ];

  defaultprofile = {
    default = true;
    visibleName = "1grey";

    scrollbackLines = 10485760; # null is meant to mean infinite but no work
    showScrollbar = true;
    scrollOnOutput = false;
    font = "UbuntuMono Nerd Font Mono 18";
    boldIsBright = true;
    audibleBell = false;

    colors = {
      palette = defaultpalette;
      backgroundColor = "#1C2023";
      foregroundColor = "#FFFFFF";
    };
  };

  sessionVariables = {
    EDITOR = "vi";
    DSSI_PATH =
      "$HOME/.dssi:$HOME/.nix-profile/lib/dssi:/run/current-system/sw/lib/dssi";
    LADSPA_PATH =
      "$HOME/.ladspa:$HOME/.nix-profile/lib/ladspa:/run/current-system/sw/lib/ladspa";
    LV2_PATH =
      "$HOME/.lv2:$HOME/.nix-profile/lib/lv2:/run/current-system/sw/lib/lv2";
    LXVST_PATH =
      "$HOME/.lxvst:$HOME/.nix-profile/lib/lxvst:/run/current-system/sw/lib/lxvst";
    VST_PATH =
      "$HOME/.vst:$HOME/.nix-profile/lib/vst:/run/current-system/sw/lib/vst";
    VST3_PATH =
      "$HOME/.vst3:$HOME/.nix-profile/lib/vst3:/run/current-system/sw/lib/vst3";
  };

  zshDotDir = ".config/zsh";

  shellAliases = {
    swnix = "sudo nixos-rebuild switch --verbose --show-trace";
    drynix = "sudo nixos-rebuild dry-build --verbose --show-trace";
    bootnix = "sudo nixos-rebuild boot --verbose --show-trace";
    ednix = "emacsclient -nw /etc/nixos/flake.nix";
    schnix = "nix search nixpkgs";
    rbnix = "sudo nixos-rebuild build --rollback";
    replnix = "nix repl '<nixpkgs>'";
    mountzfs = "sudo zfs load-key b/storage; sudo zfs mount b/storage";
    restartemacs = "systemctl --user restart emacs";
    kbrestart = "systemctl --user restart keybase";
    open = "kioclient exec";
    edit = "${pkgs-unstable.vscode-fhs}/bin/code -r";
    sgrep = "rg -M 200 --hidden"; # dont display lines > 200 chars long
    ls = "ls --color=auto";
    greyterm = "${gterm-change-profile} 1";
    blueterm = "${gterm-change-profile} 2";
    blackterm = "${gterm-change-profile} 3";
    purpleterm = "${gterm-change-profile} 4";
    yellowterm = "${gterm-change-profile} 5";
    ssh = "${ssh-chcolor}/bin/ssh-chcolor";
    ai = "shell-genie ask";
    diff = "${pkgs.colordiff}/bin/colordiff";
    python3 = "python3.11";
    python = "python3.11";
    nixos-update = "${nixos-update}";
    disable-kvm = "sudo modprobe -r kvm-intel";
    thumbnail = "${thumbnail}";
    olive-intel = "${nixgl-olive}/bin/nixGLIntel olive-editor";
  };

in

{
  imports = [ ./keybase.nix ];

  nixpkgs.config.allowUnfree = true;

  home.packages = with pkgs; [
    xdotool
    fd # fd is an unnamed dependency of fzf
    shell-genie
    nixpkgs-fmt # unnamed dependency of emacs package
  ];

  programs.gnome-terminal = {
    enable = true;
    showMenubar = false;

    profile.b1dcc9dd-5262-4d8d-a863-c897e6d979b9 = defaultprofile;
    profile.ec7087d3-ca76-46c3-a8ec-aba2f3a65db7 = defaultprofile // {
      default = false;
      visibleName = "2blue";
      colors = {
        palette = defaultpalette;
        backgroundColor = "#00008E";
        foregroundColor = "#D0CFCC";
      };
    };
    profile.ea1f3ac4-cfca-4fc1-bba7-fdf26666d188 = defaultprofile // {
      default = false;
      visibleName = "3black";
      colors = {
        palette = defaultpalette;
        backgroundColor = "#000000";
        foregroundColor = "#D0CFCC";
      };
    };
    profile.a37ed5e4-99f5-4eba-acef-e491965a6076 = defaultprofile // {
      default = false;
      visibleName = "4purple";
      colors = {
        palette = defaultpalette;
        backgroundColor = "#2C0035";
        foregroundColor = "#D0CFCC";
      };
    };
    profile.f9a98c86-a974-42bb-98a0-be84f87b9076 = defaultprofile // {
      default = false;
      visibleName = "5yellow";
      colors = {
        palette = [
          "#171421"
          "#ED1515"
          "#11D116"
          "#FF6D03"
          "#1D99F3"
          "#A347BA"
          "#2AA1B3"
          "#D0CFCC"
          "#5E5C64"
          "#F66151"
          "#33D17A"
          "#D8D8D7"
          "#2A7BDE"
          "#C061CB"
          "#33C7DE"
          "#FFFFFF"
        ];
        backgroundColor = "#F1F168";
        foregroundColor = "#000000";
      };
    };
  };

  services.gpg-agent = {
    enable = true;
    defaultCacheTtl = 1800;
    enableSshSupport = true;
  };

  xdg.configFile."black".text = ''
    [tool.black]
    line-length = 80
  '';

  programs.ssh = {
    enable = true;
    matchBlocks = {
      "lock802" = {
        user = "pi";
        forwardAgent = true;
      };
      "lock802.local" = {
        user = "pi";
        forwardAgent = true;
      };
      "192.168.1.139" = {
        user = "pi";
        forwardAgent = true;
      };
      "testlock802" = {
        user = "pi";
        forwardAgent = true;
      };
      "testlock802lan" = {
        user = "pi";
        forwardAgent = true;
      };

      "win10" = { user = "user"; };
      "thinknix*" = { forwardAgent = true; };
      "thinkcentre*" = { forwardAgent = true; };
      "bouncer.repoze.org" = { forwardAgent = true; };
      "lock802.repoze.org" = { forwardAgent = true; };
      "192.168.1.1" = { user = "root"; };
      "optinix*" = { forwardAgent = true; };
    };
  };

  xdg.configFile."environment.d/ssh_askpass.conf".text = ''
    SSH_ASKPASS="${pkgs.ksshaskpass}/bin/ksshaskpass"
  '';

  xdg.configFile."autostart/ssh-add.desktop".text = ''
    [Desktop Entry]
    Exec=ssh-add -q
    Name=ssh-add
    Type=Application
  '';

  xdg.configFile."plasma-workspace/env/ssh-agent-startup.sh" = {
    text = ''
      #!/bin/sh
      [ -n "$SSH_AGENT_PID" ] || eval "$(ssh-agent -s)"
    '';
    executable = true;
  };

  xdg.configFile."plasma-workspace/shutdown/ssh-agent-shutdown.sh" = {
    text = ''
      #!/bin/sh
      [ -z "$SSH_AGENT_PID" ] || eval "$(ssh-agent -k)"
    '';
    executable = true;
  };

  xdg.configFile."mpv/input.conf" = {
    text = ''
      PGDWN osd-msg-bar seek 5 exact
      PGUP osd-msg-bar seek -5
      Shift+PGDWN osd-msg-bar seek 30 exact
      Shift+PGUP osd-msg-bar seek -30 exact
      RIGHT osd-msg-bar seek 1 exact
      LEFT osd-msg-bar seek -1 exact
      Shift+RIGHT osd-msg-bar seek 1 exact
      Shift+LEFT osd-msg-bar seek -1 exact
      UP add volume 2
      DOWN add volume -2
      n playlist-next
      p playlist-prev
    '';
  };

  xdg.configFile."mpv/mpv.conf" = {
    text = ''
      osd-level=2
      volume=20
      volume-max=150
      autofit=100%x98%
      geometry=+50%-25
      #window-maximized
      # see https://github.com/mpv-player/mpv/issues/10229
    '';
  };

  # add Olive for nvidia-offload (as installed per video)
  xdg.desktopEntries = {
    olive-nvidia = {
      name = "Olive Video Editor (via nvidia-offload)";
      genericName = "Olive Video Editor";
      exec = "nvidia-offload olive-editor";
      terminal = false;
      categories = [ "AudioVideo" "Recorder" ];
      mimeType = [ "application/vnd.olive-project" ];
      icon = "org.olivevideoeditor.Olive";
    };
  };

  xdg.desktopEntries = {
    olive-intel = {
      name = "Olive Video Editor (via nixGLIntel)";
      genericName = "Olive Video Editor";
      exec = "${nixgl-olive}/bin/nixGLIntel olive-editor";
      terminal = false;
      categories = [ "AudioVideo" "Recorder" ];
      mimeType = [ "application/vnd.olive-project" ];
      icon = "org.olivevideoeditor.Olive";
    };
  };

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
  ];

  services.emacs = {
    enable = true;
    startWithUserSession = "graphical";
  };

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

  # uses nvidia-offload
  home.file.".local/share/applications/steam.desktop" = {
    source = ./steam.desktop;
  };

  programs.gitui.enable = true;

  programs.dircolors.enable = true;

  programs.fzf.enable = true;
  programs.fzf.enableZshIntegration = true;

  programs.bash = {
    enable = true;
    shellAliases = shellAliases;
    sessionVariables = sessionVariables;
    enableCompletion = true;
  };

  programs.zsh = {
    enable = true;
    shellAliases = shellAliases;
    sessionVariables = sessionVariables;
    enableCompletion = true;

    dotDir = zshDotDir;
    enableAutosuggestions = true;

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

      any-nix-shell zsh --info-right | source /dev/stdin

      function nix-shell () {
         # turn term color blue
         source ${gterm-color-funcs}/bin/gterm-color-funcs
         chcolor 2
         ${pkgs.any-nix-shell}/bin/.any-nix-shell-wrapper zsh "$@"
         chcolor 1
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
}
