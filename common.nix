{ config
, pkgs
, system
, inputs
, pkgs-olive
, pkgs-py36
, pkgs-py37
, pkgs-py39
, pkgs-unstable
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
    spawn -noecho nix --extra-experimental-features repl nixpkgs
    expect "nix-repl> " {
      send ":a builtins\n"
      send "pkgs = legacyPackages.${system}\n"
      interact
    }
  '';

  findnixstorelinks = pkgs.substituteAll ({
    name = "findnixstorelinks";
    src = ./bin/findnixstorelinks.py;
    dir = "/bin";
    isExecutable = true;
    py = "${pkgs.python311}/bin/python";
  });

in
{

  imports = [
    ./pkgs/cachix.nix
    ./pkgs/dvtranscode.nix
    ./pkgs/rdio-scanner
    ./pkgs/trunk-recorder
  ];

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
      experimental-features = "nix-command flakes";
      trusted-users = [ "root" "@wheel" ];
      #sandbox = "relaxed";
    };
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 30d";
    };
  };

  # NVIDIA requires nonfree
  nixpkgs.config.allowUnfree = true;
  nixpkgs.config.permittedInsecurePackages = [
    "electron-19.1.9"
    "python-2.7.18.8"
  ]; # something unknown (maybe matrix or signal desktop) and unmaintained python
  # obs
  boot.extraModulePackages = with config.boot.kernelPackages; [ v4l2loopback ];

  # rtl8153 / tp-link ue330 quirk for USB ethernet, see
  # https://askubuntu.com/questions/1081128/usb-3-0-ethernet-adapter-not-working-ubuntu-18-04
  # disables link power management for this usb ethernet adapter; won't work
  # otherwise
  boot.kernelParams = [
    "usbcore.quirks=2357:0601:k,0bda:5411:k" # ethernet, hub
  ];

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
  services.displayManager.sddm.enable = true;
  services.displayManager.defaultSession = "plasmax11";
  services.desktopManager.plasma6.enable = true;
  services.xserver.displayManager.sessionCommands =
    let modmap = pkgs.writeText "modmap" ''
      ! disable middle click
      ! pointer = 1 0 3 4 5
      ! map right-ctrl+arrow-keys to pgup/pgdn/home/end
      ! see https://forums.linuxmint.com/viewtopic.php?t=321400
      keycode 105 = Mode_switch
      keycode 113 = Left NoSymbol Home
      keycode 114 = Right NoSymbol End
      keycode 111 = Up NoSymbol Prior
      keycode 116 = Down NoSymbol Next
    '';
    in "${pkgs.xorg.xmodmap}/bin/xmodmap ${modmap}";

  services.xserver.xkb.layout = "us";
  services.xserver.xkb.options = "ctrl:nocaps,terminate:ctrl_alt_bksp";
  services.xserver.enableCtrlAltBackspace = true;
  services.xserver.dpi = 96;
  services.libinput.enable = true; # touchpad
  fonts.packages = with pkgs; [ ubuntu_font_family nerdfonts ];
  i18n.defaultLocale = "en_US.UTF-8";

  #sound.enable = false; # not needed for pipewire
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
  #virtualisation.virtualbox.host = {
  #  enable = true;
  #  enableExtensionPack = true;
  #};

  # vmVariant configuration is added only when building VM with nixos-rebuild
  # build-vm
  virtualisation.vmVariant = {
    virtualisation = {
      memorySize = 8192; # Use 8GB memory (value is in MB)
      cores = 4;
    };
  };

  # enable docker
  virtualisation.docker.enable = true;

  programs.dconf.enable = true;

  # printing
  services.printing.enable = true;
  services.avahi.enable = true;
  services.avahi.nssmdns4 = true;

  # https://discourse.nixos.org/t/newly-announced-vulnerabilities-in-cups/52771/9
  systemd.services.cups-browsed.enable = false;

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

  hardware.rtl-sdr.enable = true;
  services.udev.packages = [pkgs.airspy];

  # wireshark without sudo; note that still necessary to add
  # wireshark to systemPackages to get gui I think
  programs.wireshark.enable = true;

  # default shell for all users
  users.defaultUserShell = pkgs.zsh;
  programs.zsh.enable = true;

  programs.ssh = {
    pubkeyAcceptedKeyTypes = [ "ssh-ed25519" "ssh-rsa" ];
    hostKeyAlgorithms = [ "ssh-ed25519" "ssh-rsa" ];
    startAgent = true; # starts a systemd user service
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
    kdePackages.kdeconnect-kde
    kdePackages.krdc
    kdePackages.breeze-gtk
    kdePackages.konversation
    kdePackages.kmag
    kdePackages.kdenlive
    gnome-disk-utility
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
    transmission_3-qt
    remmina
    baobab
    signal-desktop
    python27
    pkgs.vscode-fhs
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
        python311Packages.build # for pypa build package
        python311Packages.twine # for uploading to PyPI
        python311Packages.docker
      ]))
    python312
    python313
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
    nixfmt-rfc-style
    wakeonlan
    #pkgs-olive.olive-editor # 0.1.2
    olive-editor # 0.2
    gptfdisk # "sgdisk"
    ardour
    qjackctl
    odin2
    freepats
    helm
    #distrho
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
    virt-viewer # for remote-viewer
    rpi-imager
    dig
    s3cmd
    #kaffeine
    #thonny
    cutecom
    rshell
    mplayer
    cheese
    sqlite
    tldr
    tree
    lha
    quickemu
    #quickgui
    #zenity # undeclared dep of quickgui
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
    #etcher # 24.05 removed
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
    rhythmbox
    minicom
    nvtopPackages.nvidia
    #glaxnimate # for kdenlive
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
    gitkraken
    meld
    #kdiff3
    envsubst
    appimage-run
    jq
    gucharmap
    loccount
    screenkey
    gsmartcontrol
    smartmontools
    dtc # milkv
    zstd
    protonvpn-gui
    discord
    agebox
    findnixstorelinks
    inotify-tools
    beep
    bastet # tetris
    moon-buggy
    pokete
    blender
    clinfo
    yt-dlp
    alsa-utils # aplay
    guitarix
    gxplugins-lv2
    localsend
    gparted
    gqrx
    nrsc5
    hackrf
    sdrangel
    netcat
    dsd # for gprx dmr decoding
    dsdcc # for gprx dmr decoding
    socat # for gprx dmr decoding
    sox # for play
    nickel
    gnome-boxes
    vdhcoapp # vdhcoapp install --user (see also https://github.com/NixOS/nixpkgs/issues/112046)
    airspy
    soapyairspy
    gnome-multi-writer
    util-linux # wipefs
    ipmitool
    slack
    alsa-scarlett-gui
    spice-gtk
    dive # docker
    xorg.xev
    xorg.xkbcomp
    xorg.xmodmap
    fd
    shellcheck
    inputs.isd.packages."${system}".default
  ];
}
