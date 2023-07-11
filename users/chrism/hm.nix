{ config, pkgs, home-manager, ... }:

{
  home.packages = with pkgs; [ keybase-gui ];
  home.stateVersion = "22.05";

  services.keybase.enable = true;
  services.kbfs.enable = true;

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
      "bouncer.repoze.org" = { forwardAgent = true; };
      "lock802.repoze.org" = { forwardAgent = true; };
      "192.168.1.1" = { user = "root"; };
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
    olive = {
      name = "Olive Video Editor (via nvidia-offload)";
      genericName = "Olive Video Editor";
      exec = "nvidia-offload olive-editor";
      terminal = false;
      categories = [ "AudioVideo" "Recorder" ];
      mimeType = [ "application/vnd.olive-project" ];
      icon = "org.olivevideoeditor.Olive";
    };
    # localxcalib = {
    #   name = "xcalib of ~/.monprofile.icc";
    #   genericName = "xcalib of ~/.monprofile.icc";
    #   exec = "xcalib -S :0 ${config.home.homeDirectory}/.monprofile.icc";
    #   categories = [ "Graphics" ];
    #   terminal = false;
    # };
  };

  # thanks to tejing on IRC for clueing me in to .force here: it will
  # overwrite any existing file.
  xdg.configFile."autostart/keybase_autostart.desktop".force = true;

  # default keybase_autostart.desktop doesn't run on NVIDIA in sync mode
  # without --disable-gpu-sandbox.
  xdg.configFile."autostart/keybase_autostart.desktop".text = ''
    [Desktop Entry]
    Comment[en_US]=Keybase Filesystem Service and GUI
    Comment=Keybase Filesystem Service and GUI
    Exec=env KEYBASE_AUTOSTART=1 keybase-gui --disable-gpu-sandbox
    GenericName[en_US]=
    GenericName=
    MimeType=
    Name[en_US]=Keybase
    Name=Keybase
    Path=
    StartupNotify=true
    Terminal=false
    TerminalOptions=
    Type=Application
    X-DBUS-ServiceName=
    X-DBUS-StartupType=
    X-KDE-SubstituteUID=false
    X-KDE-Username=
  '';

  programs.emacs.enable = true;
  programs.emacs.extraPackages = epkgs: [
    epkgs.nix-mode
    epkgs.flycheck
    epkgs.json-mode
    epkgs.python-mode
    epkgs.auto-complete
    epkgs.web-mode
    epkgs.smart-tabs-mode
    epkgs.whitespace-cleanup-mode
    epkgs.flycheck-pyflakes
  ];

  services.emacs.enable = true;

  home.file.".emacs.d" = {
    source = ../emacs/.emacs.d;
    recursive = true;
  };

  programs.git = {
    enable = true;
    userName = "Chris McDonough";
    userEmail = "chrism@plope.com";
  };

  home.file.".p10k.zsh" = {
    source = ../p10k/.p10k.zsh;
    executable = true;
  };

  # uses nvidia-offload
  home.file.".local/share/applications/steam.desktop" = {
    source = ../steam.desktop;
  };

  programs.zsh = {
    enable = true;
    enableAutosuggestions = true;
    enableCompletion = true;
    dotDir = ".config/zsh";

    sessionVariables = {
      EDITOR = "vi";
      LS_COLORS =
        "rs=0:di=01;34:ln=01;36:mh=00:pi=40;33:so=01;35:do=01;35:bd=40;33;01:cd=40;33;01:or=40;31;01:mi=00:su=37;41:sg=30;43:ca=00:tw=30;42:ow=34;42:st=37;44:ex=01;32:*.tar=01;31:*.tgz=01;31:*.arc=01;31:*.arj=01;31:*.taz=01;31:*.lha=01;31:*.lz4=01;31:*.lzh=01;31:*.lzma=01;31:*.tlz=01;31:*.txz=01;31:*.tzo=01;31:*.t7z=01;31:*.zip=01;31:*.z=01;31:*.dz=01;31:*.gz=01;31:*.lrz=01;31:*.lz=01;31:*.lzo=01;31:*.xz=01;31:*.zst=01;31:*.tzst=01;31:*.bz2=01;31:*.bz=01;31:*.tbz=01;31:*.tbz2=01;31:*.tz=01;31:*.deb=01;31:*.rpm=01;31:*.jar=01;31:*.war=01;31:*.ear=01;31:*.sar=01;31:*.rar=01;31:*.alz=01;31:*.ace=01;31:*.zoo=01;31:*.cpio=01;31:*.7z=01;31:*.rz=01;31:*.cab=01;31:*.wim=01;31:*.swm=01;31:*.dwm=01;31:*.esd=01;31:*.avif=01;35:*.jpg=01;35:*.jpeg=01;35:*.mjpg=01;35:*.mjpeg=01;35:*.gif=01;35:*.bmp=01;35:*.pbm=01;35:*.pgm=01;35:*.ppm=01;35:*.tga=01;35:*.xbm=01;35:*.xpm=01;35:*.tif=01;35:*.tiff=01;35:*.png=01;35:*.svg=01;35:*.svgz=01;35:*.mng=01;35:*.pcx=01;35:*.mov=01;35:*.mpg=01;35:*.mpeg=01;35:*.m2v=01;35:*.mkv=01;35:*.webm=01;35:*.webp=01;35:*.ogm=01;35:*.mp4=01;35:*.m4v=01;35:*.mp4v=01;35:*.vob=01;35:*.qt=01;35:*.nuv=01;35:*.wmv=01;35:*.asf=01;35:*.rm=01;35:*.rmvb=01;35:*.flc=01;35:*.avi=01;35:*.fli=01;35:*.flv=01;35:*.gl=01;35:*.dl=01;35:*.xcf=01;35:*.xwd=01;35:*.yuv=01;35:*.cgm=01;35:*.emf=01;35:*.ogv=01;35:*.ogx=01;35:*.aac=00;36:*.au=00;36:*.flac=00;36:*.m4a=00;36:*.mid=00;36:*.midi=00;36:*.mka=00;36:*.mp3=00;36:*.mpc=00;36:*.ogg=00;36:*.ra=00;36:*.wav=00;36:*.oga=00;36:*.opus=00;36:*.spx=00;36:*.xspf=00;36:*~=00;90:*#=00;90:*.bak=00;90:*.old=00;90:*.orig=00;90:*.part=00;90:*.rej=00;90:*.swp=00;90:*.tmp=00;90:*.dpkg-dist=00;90:*.dpkg-old=00;90:*.ucf-dist=00;90:*.ucf-new=00;90:*.ucf-old=00;90:*.rpmnew=00;90:*.rpmorig=00;90:*.rpmsave=00;90:";
    };

    shellAliases = {
      swnix = "sudo nixos-rebuild switch --verbose";
      drynix = "sudo nixos-rebuild dry-build --verbose";
      bootnix = "sudo nixos-rebuild boot --verbose";
      ednix = "emacsclient -nw /etc/nixos/flake.nix";
      schnix = "nix search nixpkgs";
      rbnix = "sudo nixos-rebuild build --rollback";
      replnix = "nix repl '<nixpkgs>'";
      mountzfs = "sudo zfs load-key z/storage; sudo zfs mount z/storage";
      restartemacs = "systemctl --user restart emacs";
      open = "kioclient exec";
      edit = "emacsclient -n -c";
      sgrep = "rg";
      ls = "ls --color=auto";
    };

    completionInit = ""; # speed up start time

    #initExtraFirst = ''
    #  zmodload zsh/zprof
    #'';

    initExtra = ''
      # be more bashy
      setopt interactive_comments bashautolist nobeep nomenucomplete noautolist

      ## include config generated via "p10k configure" manually;
      ## zplug cannot edit home manager's zshrc file.

      [[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

      ## Keybindings section
      bindkey -e
      bindkey '^[[7~' beginning-of-line                               # Home key
      bindkey '^[[H' beginning-of-line                                # Home key
      if [[ "''${terminfo[khome]}" != "" ]]; then
      bindkey "''${terminfo[khome]}" beginning-of-line                # [Home] - Go to beginning of line
      fi
      bindkey '^[[8~' end-of-line                                     # End key
      bindkey '^[[F' end-of-line                                     # End key
      if [[ "''${terminfo[kend]}" != "" ]]; then
      bindkey "''${terminfo[kend]}" end-of-line                       # [End] - Go to end of line
      fi
      bindkey '^[[2~' overwrite-mode                                  # Insert key
      bindkey '^[[3~' delete-char                                     # Delete key
      bindkey '^[[C'  forward-char                                    # Right key
      bindkey '^[[D'  backward-char                                   # Left key
      bindkey '^[[5~' history-beginning-search-backward               # Page up key
      bindkey '^[[6~' history-beginning-search-forward                # Page down key
      # Navigate words with ctrl+arrow keys
      bindkey '^[Oc' forward-word                                     #
      bindkey '^[Od' backward-word                                    #
      bindkey '^[[1;5D' backward-word                                 #
      bindkey '^[[1;5C' forward-word                                  #
      bindkey '^H' backward-kill-word                                 # delete previous word with ctrl+backspace
      bindkey '^[[Z' undo                                             # Shift+tab undo last action
      # Theming section
      autoload -U colors
      colors
      #zprof
    '';
    zplug = {
      enable = true;
      plugins = [{
        name = "romkatv/powerlevel10k";
        tags = [ "as:theme" "depth:1" ];
      }];
    };
  };
}
