{ config
, lib
, pkgs
, system
, pkgs-olive
, pkgs-py36
, pkgs-py37
, pkgs-py39
, pkgs-unstable
, nixpkgs
, ...
}:

let
  # prefer over using hardware.nvidia.prime.offload.enableOffloadCmd = true;
  # because that is only true when offload mode is turned on (see
  # pseries.nix where it's turned off for isolation from nixos-hardware
  # upstream changes)
  nvidia-offload = pkgs.writeShellScriptBin "nvidia-offload" ''
    export __NV_PRIME_RENDER_OFFLOAD=1
    export __NV_PRIME_RENDER_OFFLOAD_PROVIDER=NVIDIA-G0
    export __GLX_VENDOR_LIBRARY_NAME=nvidia
    export __VK_LAYER_NV_optimus=NVIDIA_only
    exec "$@"
  '';

  start-virsh = pkgs.writeShellScriptBin "start-virsh" ''
    sudo virsh net-list --all
    sudo virsh net-autostart default
    sudo virsh net-start default
  '';

  nixos-repl = pkgs.writeScriptBin "nixos-repl" ''
    #!/usr/bin/env ${pkgs.expect}/bin/expect
    set timeout 120
    spawn -noecho nix --extra-experimental-features repl-flake repl nixpkgs
    expect "nix-repl> " {
      send ":a builtins\n"
      send "pkgs = legacyPackages.${system}\n"
      interact
    }
  '';

  gitkraken-wimpy = pkgs.callPackage ./pkgs/gitkraken.nix { };
  dvtranscode = pkgs.callPackage ./pkgs/dvtranscode.nix { };

  findnixstorelinks = pkgs.substituteAll ({
    name = "findnixstorelinks";
    src = ./bin/findnixstorelinks.py;
    dir = "/bin";
    isExecutable = true;
    py = "${pkgs.python311}/bin/python";
  });

in
{

  imports = [ ./pkgs/cachix.nix ];

  # see https://chattingdarkly.org/@lhf@fosstodon.org/110661879831891580
  system.activationScripts.diff = {
    supportsDryActivation = true;
    text = ''
      ${pkgs.nvd}/bin/nvd --nix-bin-dir=${pkgs.nix}/bin diff \
           /run/current-system "$systemConfig"
    '';
  };

  nix = {
    settings = {
      tarball-ttl = 300;
      auto-optimise-store = true;
      experimental-features = "nix-command flakes repl-flake";
      trusted-users = [ "root" "@wheel" ];
      sandbox = "relaxed";
    };
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 30d";
    };
    # don't fetch nixpkgs-unstable for every "nix shell" / "nix run"
    # https://dataswamp.org/~solene/2022-07-20-nixos-flakes-command-sync-with-system.html
    registry = {
      nixpkgs.flake = nixpkgs;
    };
    nixPath = [ "nixpkgs=${nixpkgs}" ];
  };

  # NVIDIA requires nonfree
  nixpkgs.config.allowUnfree = true;
  nixpkgs.config.permittedInsecurePackages = [
    "electron-19.1.9"
    "python-2.7.18.6"
    "python-2.7.18.7"
  ]; # etcher (12.2.3), something unknown (maybe matrix or signal desktop) and
  # unmaintained python

  # obs
  boot.extraModulePackages = with config.boot.kernelPackages; [ v4l2loopback ];

  # rtl8153 / tp-link ue330 quirk for USB ethernet, see
  # https://askubuntu.com/questions/1081128/usb-3-0-ethernet-adapter-not-working-ubuntu-18-04
  # disables link power management for this usb ethernet adapter; won't work
  # otherwise
  boot.kernelParams = [
    "usbcore.quirks=2357:0601:k,0bda:5411:k" # ethernet, hub
  ];

  # behave as a router
  boot.kernel.sysctl = {
    "net.ipv4.conf.all.forwarding" = true;
  };

  # see https://github.com/musnix/musnix
  # Activate the performance CPU frequency scaling governor.
  # Set vm.swappiness to 10.
  # Set the following udev rules (enable high-precision timers, if they exist):
  #  KERNEL=="rtc0", GROUP="audio"
  #  KERNEL=="hpet", GROUP="audio"
  # Set the following PAM limits:
  #  @audio  -       memlock unlimited
  #  @audio  -       rtprio  99
  #  @audio  soft    nofile  99999
  #  @audio  hard    nofile  99999
  # Set environment variables to default install locations in NixOS:
  #  VST_PATH
  #  VST3_PATH
  #  LXVST_PATH
  #  LADSPA_PATH
  #  LV2_PATH
  #  DSSI_PATH
  # Allow users to install plugins in the following directories:
  #  ~/.vst
  #  ~/.vst3
  #  ~/.lxvst
  #  ~/.ladspa
  #  ~/.lv2
  #  ~/.dssi
  # Musnix.alsaSql.enable does
  #  boot.kernelModules = [ "snd-seq" "snd-rawmidi" ];

  musnix.enable = true;
  musnix.alsaSeq.enable = true;

  # match "Jun 19 13:00:01 thinknix512 cupsd[2350]: Expiring subscriptions..."
  systemd.services.cups = {
    overrideStrategy = "asDropin";
    serviceConfig.LogFilterPatterns = "~.*Expiring subscriptions.*";
  };

  # restart faster
  systemd.extraConfig = ''
    DefaultTimeoutStopSec=10s
  '';

  networking.networkmanager.enable = true;
  networking.firewall.enable = false;

  time.timeZone = "America/New_York";

  hardware.bluetooth.enable = true;
  hardware.enableAllFirmware = true;

  hardware.flipperzero.enable = true;

  # desktop stuff
  services.xserver.enable = true;
  services.xserver.displayManager.sddm.enable = true;
  services.xserver.desktopManager.plasma5.enable = true;
  services.xserver.layout = "us";
  services.xserver.xkbOptions = "ctrl:nocaps,terminate:ctrl_alt_bksp";
  services.xserver.enableCtrlAltBackspace = true;
  services.xserver.dpi = 96;
  services.xserver.libinput.enable = true; # touchpad
  fonts.packages = with pkgs; [ ubuntu_font_family nerdfonts ];

  sound.enable = false; # not needed for pipewire
  hardware.pulseaudio.enable = false;
  services.pipewire = {
    enable = true;
    alsa = {
      enable = true;
      support32Bit = true;
    };
    jack.enable = true;
    pulse.enable = true;
  };

  # virtualization
  virtualisation.libvirtd.enable = true;
  virtualisation.virtualbox.host = {
    enable = true;
    enableExtensionPack = true;
  };

  # vmVariant configuration is added only when building VM with nixos-rebuild
  # build-vm
  virtualisation.vmVariant = {
    virtualisation = {
      memorySize = 8192; # Use 8GB memory (value is in MB)
      cores = 4;
    };
  };

  programs.dconf.enable = true;

  # printing
  services.printing.enable = true;
  services.avahi.enable = true;
  services.avahi.nssmdns = true;

  # all other services
  services.fwupd.enable = true;
  services.locate.enable = false;
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      PermitRootLogin = "no";
    };
  };

  # enable docker
  virtualisation.docker.enable = true;

  # wireshark without sudo; note that still necessary to add
  # wireshark to systemPackages to get gui I think
  programs.wireshark.enable = true;

  # default shell for all users
  users.defaultUserShell = pkgs.zsh;
  programs.zsh.enable = true;

  programs.ssh = {
    pubkeyAcceptedKeyTypes = [ "ssh-ed25519" "ssh-rsa" ];
    hostKeyAlgorithms = [ "ssh-ed25519" "ssh-rsa" ];
  };

  # enable nix-ld for pip and friends
  #programs.nix-ld.enable = true;

  users.groups.nixconfig = { };

  # # this causes weirdness when vim is exited, printing mouse movements
  # # as ANSI sequences on any terminal; use shift to select text as a
  # # workaround
  # environment.etc."vimrc".text = ''
  #   " get rid of maddening mouseclick-moves-cursor behavior
  #   set mouse=
  #   set ttymouse=
  # '';

  # run appimages directly (see https://nixos.wiki/wiki/Appimage)
  boot.binfmt = {
    registrations.appimage = {
      wrapInterpreterInShell = false;
      interpreter = "${pkgs.appimage-run}/bin/appimage-run";
      recognitionType = "magic";
      offset = 0;
      mask = "\\xff\\xff\\xff\\xff\\x00\\x00\\x00\\x00\\xff\\xff\\xff";
      magicOrExtension = "\\x7fELF....AI\\x02";
    };
    # run aarch64 binaries
    emulatedSystems = [ "aarch64-linux" ];
  };

  environment.variables = {
    # override musnix to add $HOME/.vst to LXVST_PATH (for yabridge)
    LXVST_PATH =
      lib.mkForce "$HOME/.vst:$HOME/.lxvst:$HOME/.nix-profile/lib/lxvst:/run/current-system/sw/lib/lxvst";
    EDITOR = "vi";
  };

  environment.systemPackages = with pkgs; [
    cachix
    nvidia-offload
    vim-full
    wget
    (wrapOBS {
      plugins = with pkgs.obs-studio-plugins; [ obs-backgroundremoval ];
    })
    thermald
    powertop
    libsForQt5.kdeconnect-kde
    libsForQt5.krdc
    libsForQt5.breeze-gtk
    libsForQt5.konversation
    libsForQt5.kmag
    gnome.gnome-disk-utility
    openvpn
    unzip
    ripgrep
    btop
    killall
    htop
    handbrake
    mpv
    vlc
    google-chrome
    firefox
    audacity
    gimp
    transmission-qt
    remmina
    baobab
    signal-desktop
    python27
    pkgs-unstable.vscode-fhs
    pkgs-py36.python36
    pkgs-py37.python37
    pkgs-py39.python38
    pkgs-py39.python39
    python310
    (python311.withPackages (p:
      with p; [
        python311Packages.pyserial # for pico-w-go in vscode
        python311Packages.pyflakes # for emacs
        python311Packages.flake8 # for emacs/vscode
        python311Packages.docutils # for vscode
        python311Packages.pygments # for vscode
        python311Packages.black # for cmdline and vscode
        python311Packages.tox # for... tox
      ]))
    pypy3
    xz
    libreoffice
    ffmpeg-full
    iperf
    pciutils
    neofetch
    tmux
    s-tui
    stress-ng
    usbutils
    nmap
    zoom-us
    konversation
    pkgs-unstable.nixfmt-rfc-style
    wakeonlan
    #pkgs-olive.olive-editor # 0.1.2
    olive-editor # 0.2
    gptfdisk # "sgdisk"
    ardour
    qjackctl
    odin2
    freepats
    helm
    distrho
    calf
    x42-plugins
    tap-plugins
    zam-plugins
    setbfree
    x42-avldrums
    zynaddsubfx
    sfizz
    #vcv-rack # (uncached)
    hydrogen
    surge-XT
    #lsp-plugins # (too many plugins)
    sanoid
    hplip
    geteltorito
    argyllcms
    xcalib
    virt-manager
    rpi-imager
    dig
    s3cmd
    kaffeine
    pcmanfm-qt
    thonny
    cutecom
    rshell
    mplayer
    gnome.cheese
    sqlite
    tldr
    tree
    lha
    quickemu
    quickgui
    gnome.zenity # undeclared dep of quickgui
    nix-du
    graphviz
    zgrviewer
    bintools # "strings"
    thinkfan
    lm_sensors
    cntr # for build debugging
    gnupg
    pinentry # dep of gpg
    age # for flyingcircus
    lsof
    progress
    mc
    etcher
    pre-commit
    html-tidy
    dua
    duf
    ncdu
    inetutils # for telnet
    asciiquarium
    rig
    cowsay
    banner
    lolcat
    fortune
    file
    ruby
    nix-tree
    fdupes
    dupe-krill
    dupeguru
    pv
    fio
    mbuffer
    qjournalctl
    gnumake
    bat
    ethtool
    wol
    imagemagick
    audiowaveform
    element-desktop
    speech-denoiser
    rnnoise-plugin
    pkgs-unstable.rhythmbox
    minicom
    nvtop-nvidia
    libsForQt5.kdenlive
    glaxnimate # for kdenlive
    nix-index # for nix-locate
    bitwarden
    any-nix-shell
    pico-sdk
    sdcc
    dstat
    speedtest-cli
    fast-cli
    nmap
    bottom
    wireshark
    openssl
    geekbench
    start-virsh
    nixos-repl
    lazygit
    gittyup
    github-desktop
    gitkraken-wimpy
    meld
    kdiff3
    envsubst
    appimage-run
    jq
    gnome.gucharmap
    loccount
    screenkey
    gsmartcontrol
    smartmontools
    dtc # milkv
    zstd
    pkgs-unstable.protonvpn-gui
    discord
    agebox
    findnixstorelinks
    inotify-tools
    beep
    bastet # tetris
    moon-buggy
    pokete
    blender
    dvtranscode
    clinfo
    yt-dlp
    # https://github.com/WolfangAukang/nur-packages/issues/9#issuecomment-1089072988
    # share/vdhcoapp/net.downloadhelper.coapp install --user
    #config.nur.repos.wolfangaukang.vdhcoapp
  ];
}
