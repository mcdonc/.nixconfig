{ config, pkgs, home-manager, ... }:

{
  home.packages = with pkgs; [
    keybase-gui
    # fd is an unnamed dependency of fzf
    fd
    shell-genie
  ];
  home.stateVersion = "22.05";

  services.keybase.enable = true;
  services.kbfs.enable = true;

  xdg.configFile."black".text = ''
    [tool.black]
    line-length = 80
  '';

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

  services.emacs = {
    enable = true;
    startWithUserSession = "graphical";
  };

  home.file.".emacs.d" = {
    source = ../.emacs.d;
    recursive = true;
  };

  programs.git = {
    enable = true;
    userName = "Larry";
    userEmail = "larry@agendaless.com";
  };

  home.file.".p10k.zsh" = {
    source = ../.p10k.zsh;
    executable = true;
  };

  # uses nvidia-offload
  home.file.".local/share/applications/steam.desktop" = {
    source = ../steam.desktop;
  };

  programs.gitui.enable = true;

  programs.dircolors.enable = true;
  programs.fzf.enable = true;
  programs.fzf.enableZshIntegration = true;

  programs.zsh = {
    enable = true;
    enableAutosuggestions = true;
    enableCompletion = true;
    dotDir = ".config/zsh";

    sessionVariables = {
      EDITOR = "vi";
    };

    shellAliases = {
      swnix = "sudo nixos-rebuild switch --verbose";
      drynix = "sudo nixos-rebuild dry-build --verbose";
      bootnix = "sudo nixos-rebuild boot --verbose";
      ednix = "emacsclient -nw /etc/nixos/flake.nix";
      schnix = "nix search nixpkgs";
      rbnix = "sudo nixos-rebuild build --rollback";
      replnix = "nix repl '<nixpkgs>'";
      restartemacs = "systemctl --user restart emacs";
      open = "kioclient exec";
      edit = "emacsclient -n -c";
      sgrep = "rg -M 200"; # dont display lines > 200 chars long
      ls = "ls --color=auto";
      ai = "shell-genie ask";
      diff = "${pkgs.colordiff}/bin/colordiff";
      python3 = "python3.11";
      python = "python3.11";
    };

    completionInit = ""; # speed up zsh start time

    #initExtraFirst = ''
    # zmodload zsh/zprof
    #'';

    initExtra = ''
      # be more bashy
      setopt interactive_comments bashautolist nobeep nomenucomplete noautolist


      ## include config generated via "p10k configure" manually;
      ## zplug cannot edit home manager's zshrc file.

      [[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

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
