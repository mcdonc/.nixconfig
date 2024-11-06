{ pkgs, nixgl-olive, nixgl-unstable, ... }:

let

  nixos-update = pkgs.writeShellScript "nixos-update" ''
    cd /etc/nixos
    git pull
    nix flake update
    sudo nixos-rebuild switch --verbose
  '';

  nixfmt80 = pkgs.writeShellScriptBin "nixfmt80" ''
    ${pkgs.nixfmt-rfc-style}/bin/nixfmt -w80 $@
  '';

  gterm-change-profile = "xdotool key --clearmodifiers Shift+F10 r";

  ssh-chcolor = pkgs.writeShellScript "ssh-chcolor" ''
    source ${gterm-color-funcs}
    chcolor 5
    ${pkgs.openssh}/bin/ssh $@
    if [ $? -ne 0 ]; then
       trap 'colorbye' SIGINT
       echo -e "\e[31mSSH exited unexpectedly, hit enter to continue\e[0m"
       read -p ""
    fi
    chcolor 1
  '';

  gterm-color-funcs = pkgs.writeShellScript "gterm-color-funcs" ''
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

  ffmpeg = "${pkgs.ffmpeg-full}/bin/ffmpeg";

  thumbnail = pkgs.writeShellScript "thumbnail" ''
    # writes to ./thumbnail.png
    # thumbnail eyedrops2.mp4 00:01:07
    ${ffmpeg} -y -i "$1" -ss "$2" \
      -vframes 1 thumbnail.png > /dev/null 2>&1
  '';

  extractmonopcm = pkgs.writeShellScript "extractmonopcm" ''
    ${ffmpeg} -i "$1" -map 0:a:0 -ac 1 -f s16le -acodec pcm_s16le "$2"
  '';

  yt-1080p = pkgs.writeShellScript "yt-1080p" ''
    # assumes 4k input
    ${ffmpeg} -i "$1" -c:v h264_nvenc -rc:v vbr -b:v 10M \
       -vf "scale=1920:1080" -r 30 -c:a aac -b:a 128k -movflags +faststart "$2"
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

  sessionVariables = {};

  zshDotDir = ".config/zsh";

  shellAliases = {
    swnix = "sudo nixos-rebuild switch --verbose --show-trace";
    drynix = "sudo nixos-rebuild dry-build --verbose --show-trace";
    bootnix = "sudo nixos-rebuild boot --verbose --show-trace";
    ednix = "emacsclient -nw /etc/nixos/flake.nix";
    schnix = "nix search nixpkgs";
    rbnix = "sudo nixos-rebuild build --rollback";
    replnix = "nix repl '<nixpkgs>'";
    mountzfs = "sudo zfs load-key d/o; sudo zfs mount d/o";
    restartemacs = "systemctl --user restart emacs";
    kbrestart = "systemctl --user restart keybase";
    toconsole = "sudo systemd isolate multi-user.target";
    togui = "sudo systemd isolate graphical.target";
    open = "kioclient exec";
    edit = "emacsclient -n -c";
    sgrep = "rg -M 200 --hidden"; # dont display lines > 200 chars long
    ls = "ls --color=auto";
    greyterm = "${gterm-change-profile} 1";
    blueterm = "${gterm-change-profile} 2";
    blackterm = "${gterm-change-profile} 3";
    purpleterm = "${gterm-change-profile} 4";
    yellowterm = "${gterm-change-profile} 5";
    ssh = "${ssh-chcolor}";
    ai = "shell-genie ask";
    diff = "${pkgs.colordiff}/bin/colordiff";
    python3 = "python3.11";
    python = "python3.11";
    nixos-update = "${nixos-update}";
    disable-kvm = "sudo modprobe -r kvm-intel";
    thumbnail = "${thumbnail}";
    yt-1080p = "${yt-1080p}";
    extractmonopcm = "${extractmonopcm}";
    olive-intel = "${nixgl-unstable}/bin/nixGLIntel olive-editor";
    stopx = "${pkgs.systemd}/bin/systemctl stop display-manager.service";
    startx = "${pkgs.systemd}/bin/systemctl start display-manager.service";
  };

in

{
  services.keybase.enable = true;
  services.kbfs.enable = true;

  nixpkgs.config.allowUnfree = true;

  home.packages = with pkgs; [
    xdotool
    fd # fd is an unnamed dependency of fzf
    shell-genie
    nixpkgs-fmt # unnamed dependency of emacs package
    nixfmt80
    keybase-gui
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
      "keithmoon" = {
        forwardAgent = true;
      };

      "win10" = { user = "user"; };
      "thinknix*" = { forwardAgent = true; };
      "nixcentre" = { forwardAgent = true; };
      "bouncer.repoze.org" = { forwardAgent = true; };
      "lock802.repoze.org" = { forwardAgent = true; };
      "192.168.1.1" = { user = "root"; };
      "optinix" = { forwardAgent = true; };
      "apex.firewall" = {
        hostname = "apex.firewall";
        proxyJump = "bouncer.palladion.com";
        forwardAgent = true;
        serverAliveInterval = 60;
        localForwards = [
          # windresource
          {
            bind.port = 56526;
            host.port = 56526;
            host.address = "apex-gis.ace.apexcleanenergy.com";
          }
          # 8760, techdash, gisproject
          {
            bind.port = 1433;
            host.port = 1433;
            host.address = "ace-ra-sql1.ace.apexcleanenergy.com";
          }
          # mongo
          {
            bind.port = 27017;
            host.port = 27017;
            host.address = "ace-web-test.ace.apexcleanenergy.com";
          }
        ];
      };
    };
  };

  xdg.configFile."environment.d/ssh_askpass.conf".text = ''
    SSH_ASKPASS="${pkgs.kdePackages.ksshaskpass}/bin/ksshaskpass"
  '';

  # relies on Nix programs.ssh.startAgent
  xdg.configFile."autostart/ssh-add.desktop".text = ''
    [Desktop Entry]
    Exec=${pkgs.openssh}/bin/ssh-add -q
    Name=ssh-add
    Type=Application
  '';

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
      r cycle_values video-rotate 90 180 270 0
      Alt+- add video-zoom -0.25
      Alt+= add video-zoom 0.25
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
    epkgs.editorconfig
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

      any-nix-shell zsh --info-right | source /dev/stdin

      function nix-shell () {
         # turn term color blue
         source ${gterm-color-funcs}
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
