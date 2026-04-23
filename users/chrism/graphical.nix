{ pkgs, lib, ... }:

let
  mkCaseEntry = scheme:
    ''${toString scheme.num}) BG="${scheme.bg}"; FG="${scheme.fg}"
         PAL="${paletteToShellStr scheme.palette}" ;;'';

  gterm-change-profile = pkgs.writeShellScript "gterm-change-profile" ''
    case "$1" in
      ${builtins.concatStringsSep "\n      " (map mkCaseEntry colorschemes)}
      *) return ;;
    esac
    printf "\e]10;%s\a" "$FG"
    printf "\e]11;%s\a" "$BG"
    i=0
    for color in $PAL; do
      printf "\e]4;%d;%s\a" "$i" "$color"
      i=$((i + 1))
    done
  '';

  # ffmpeg scripts (workstation-only due to large closure size ~1.5GB)
  ffmpeg = "${pkgs.ffmpeg-full}/bin/ffmpeg";

  yt-transcode = pkgs.writeShellScriptBin "yt-transcode" ''
    ffmpeg -i "$1" -c:v h264_nvenc -preset slow -cq 23 -c:a aac -b:a 192k \
      -movflags +faststart output.mp4
  '';

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
      # switches terminal colors using OSC escape sequences
      ${gterm-change-profile} $1
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

  colorschemes = [
    { num = 1; name = "grey";   uuid = "b1dcc9dd-5262-4d8d-a863-c897e6d979b9";
      bg = "#1C2023"; fg = "#FFFFFF"; palette = defaultpalette; default = true; }
    { num = 2; name = "blue";   uuid = "ec7087d3-ca76-46c3-a8ec-aba2f3a65db7";
      bg = "#00008E"; fg = "#D0CFCC"; palette = defaultpalette; default = false; }
    { num = 3; name = "black";  uuid = "ea1f3ac4-cfca-4fc1-bba7-fdf26666d188";
      bg = "#000000"; fg = "#D0CFCC"; palette = defaultpalette; default = false; }
    { num = 4; name = "purple"; uuid = "a37ed5e4-99f5-4eba-acef-e491965a6076";
      bg = "#2C0035"; fg = "#D0CFCC"; palette = defaultpalette; default = false; }
    { num = 5; name = "yellow"; uuid = "f9a98c86-a974-42bb-98a0-be84f87b9076";
      bg = "#F1F168"; fg = "#000000"; default = false;
      palette = [
        "#171421" "#ED1515" "#11D116" "#FF6D03" "#1D99F3" "#A347BA" "#2AA1B3" "#D0CFCC"
        "#5E5C64" "#F66151" "#33D17A" "#D8D8D7" "#2A7BDE" "#C061CB" "#33C7DE" "#FFFFFF"
      ]; }
  ];

  paletteToShellStr = pal: builtins.concatStringsSep " " pal;

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

  mkProfile = scheme: defaultprofile // {
    default = scheme.default;
    visibleName = "${toString scheme.num}${scheme.name}";
    colors = {
      palette = scheme.palette;
      backgroundColor = scheme.bg;
      foregroundColor = scheme.fg;
    };
  };

  termsettings = {
    enable = true;
    showMenubar = false;
    profile = builtins.listToAttrs (map (scheme: {
      name = scheme.uuid;
      value = mkProfile scheme;
    }) colorschemes);
  };

  termAliases = builtins.listToAttrs (map (scheme: {
    name = "${scheme.name}term";
    value = "${gterm-change-profile} ${toString scheme.num}";
  }) colorschemes);

  shellAliases = termAliases // {
    ssh = "${ssh-chcolor}";
    stopx = "${pkgs.systemd}/bin/systemctl stop display-manager.service";
    startx = "${pkgs.systemd}/bin/systemctl start display-manager.service";
    macos = "quickemu --vm $HOME/.local/share/quickemu/macos-sonoma.conf --width 1920 --height 1080 --display spice --viewer remote-viewer";
    ubuntu = "quickemu --vm $HOME/.local/share/quickemu/ubuntu-24.04.conf --width 1920 --height 1080 --display spice --viewer remote-viewer";
    windows = "quickemu --vm $HOME/.local/share/quickemu/windows-10.conf --width 1920 --height 1200 --display spice";
    thumbnail = "${thumbnail}";
    yt-1080p = "${yt-1080p}";
    extractmonopcm = "${extractmonopcm}";
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
    initContent = lib.mkAfter ''
      source ${gterm-color-funcs}
      function nix-shell () {
         # turn term color blue
         pushcolor 2
         command nix-shell "$@"
         popcolor
      }

      function devenv () {
         # turn term color blue
         pushcolor 4
         command devenv "$@"
         popcolor
      }

    '';
  };

  xdg.configFile."environment.d/ssh_askpass.conf".text = ''
    SSH_ASKPASS="${pkgs.kdePackages.ksshaskpass}/bin/ksshaskpass"
    SSH_ASKPASS_REQUIRE=prefer
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
    6 playlist-play-index 0
    Shift+6 playlist-play-index 0
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
    yt-transcode
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
