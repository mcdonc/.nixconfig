{ pkgs, lib, ... }:

let
  gterm-change-profile = "${pkgs.xdotool}/bin/xdotool key --clearmodifiers Shift+F10 r";

  ssh-chcolor = pkgs.writeShellScript "ssh-chcolor" ''
    source ${gterm-color-funcs}
    pushcolor 5
    ${pkgs.openssh}/bin/ssh $@
    if [ $? -ne 0 ]; then
       trap 'colorbye' SIGINT
       echo -e "\e[31mSSH exited unexpectedly, hit enter to continue\e[0m"
       read -p ""
    fi
    popcolor
  '';

  gterm-color-funcs = pkgs.writeShellScript "gterm-color-funcs" ''
    if [ -z "$COLORSTACK" ]; then
      export COLORSTACK="1"
    fi
    function chcolor() {
      # emulates right-clicking and selecting a numbered gnome-terminal
      # profile. hide output if it fails.  --clearmodifiers ignores any
      # modifier keys you're physically holding before sending the command
      if [ -n "$GNOME_TERMINAL_SERVICE" ]; then
         ${gterm-change-profile} $1 > /dev/null 2>&1
      fi
    }

    function colorbye () {
      popcolor
      exit
    }

    pushcolor() {
      chcolor $1
      if [ -z "$COLORSTACK" ]; then
        export COLORSTACK="$1"
      else
        export COLORSTACK="$COLORSTACK:$1"
      fi
    }

    popcolor() {
      export COLORSTACK="$(echo "$COLORSTACK" | rev | cut -d: -f2- | rev)"
      if [ -z "$COLORSTACK" ]; then
        export COLORSTACK="1"
      fi
      local top="$(awk -F: '{print $NF}' <<< "$COLORSTACK")"
      if [ -z "$top" ]; then
        local top=1
      fi
      chcolor "$top"
    }
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

  termsettings = {
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

  shellAliases = {
    greyterm = "${gterm-change-profile} 1";
    blueterm = "${gterm-change-profile} 2";
    blackterm = "${gterm-change-profile} 3";
    purpleterm = "${gterm-change-profile} 4";
    yellowterm = "${gterm-change-profile} 5";
    #ssh = "${ssh-chcolor}";
    stopx = "${pkgs.systemd}/bin/systemctl stop display-manager.service";
    startx = "${pkgs.systemd}/bin/systemctl start display-manager.service";
    macos = "quickemu --vm $HOME/.local/share/quickemu/macos-sonoma.conf --width 1920 --height 1080 --display spice --viewer remote-viewer";
    ubuntu = "quickemu --vm $HOME/.local/share/quickemu/ubuntu-24.04.conf --width 1920 --height 1080 --display spice --viewer remote-viewer";
    windows = "quickemu --vm $HOME/.local/share/quickemu/windows-10.conf --width 1920 --height 1200 --display spice";
  };

in
{

  # uncomment imports and comment keybase services to go back to
  # unsandboxed gpu setup if necessary
  #imports = [ ./keybase.nix ];
  services.keybase.enable = true;
  services.kbfs.enable = true;

  programs.gnome-terminal = termsettings;

  programs.bash = {
    shellAliases = shellAliases;
  };

  programs.zsh = {
    shellAliases = shellAliases;
    # initContent = lib.mkAfter ''
    #   source ${gterm-color-funcs}
    #   function nix-shell () {
    #      # turn term color blue
    #      pushcolor 2
    #      ${pkgs.any-nix-shell}/bin/.any-nix-shell-wrapper zsh "$@"
    #      popcolor
    #   }

    #   function devenv () {
    #      # turn term color blue
    #      pushcolor 4
    #      $HOME/.nix-profile/bin/devenv "$@"
    #      popcolor
    #   }

    # '';
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

  xdg.configFile."mpv/input.conf".text = ''
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

  xdg.configFile."mpv/mpv.conf".text = ''
    osd-level=2
    volume=20
    volume-max=150
    autofit=100%x98%
    geometry=+50%-25
    #window-maximized
    # see https://github.com/mpv-player/mpv/issues/10229
  '';

  services.emacs.startWithUserSession = "graphical";

  home.packages = with pkgs; [
    keybase-gui
    keybase
  ];

  # uses nvidia-offload
  home.file.".local/share/applications/steam.desktop" = {
    source = ./steam.desktop;
  };

  # add Olive for nvidia-offload (as installed per video)
  # xdg.desktopEntries = {
  #   olive-nvidia = {
  #     name = "Olive Video Editor (via nvidia-offload)";
  #     genericName = "Olive Video Editor";
  #     exec = "nvidia-offload olive-editor";
  #     terminal = false;
  #     categories = [ "AudioVideo" "Recorder" ];
  #     mimeType = [ "application/vnd.olive-project" ];
  #     icon = "org.olivevideoeditor.Olive";
  #   };
  #   olive-intel = {
  #     name = "Olive Video Editor (via nixGLIntel)";
  #     genericName = "Olive Video Editor";
  #     exec = "${nixgl-olive}/bin/nixGLIntel olive-editor";
  #     terminal = false;
  #     categories = [ "AudioVideo" "Recorder" ];
  #     mimeType = [ "application/vnd.olive-project" ];
  #     icon = "org.olivevideoeditor.Olive";
  #   };
  # };

}
