{ pkgs
, pkgs-py36
, pkgs-py37
, pkgs-py39
, inputs
, system
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

  findnixstorelinks = pkgs.writers.writePython3Bin "findnixstorelinks"
    {} (builtins.readFile ../../../bin/findnixstorelinks.py);

  python313WithPackages = (
    pkgs.python313.withPackages (p:
      with p; [
        pyserial # for pico-w-go in vscode
        pyflakes # for emacs
        flake8 # for emacs/vscode
        docutils # for vscode
        pygments # for vscode
        black # for cmdline and vscode
        tox
        build # for pypa build package
        twine # for uploading to PyPI
        python-lsp-server # for emacs lsp
      ])
  );

  syspython = pkgs.writeScriptBin "syspython" ''
      exec ${python313WithPackages}/bin/python $@
  '';
in
{
  nixpkgs.config.permittedInsecurePackages = [
   "python-2.7.18.8"
  ]; # unmaintained python

  environment.systemPackages = with pkgs; [
    cachix
    nvidia-offload
    vim-full
    wget
    (wrapOBS {
      plugins = [ pkgs.obs-studio-plugins.obs-backgroundremoval ];
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
    alsa-utils
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
    pkgs.vscode-fhs
    # the order of python3s is intentional; python313 will be first the PATH
    python313WithPackages
    syspython
    pkgs-py36.python36
    pkgs-py37.python37
    pkgs-py39.python38
    pkgs-py39.python39
    python310
    python311
    python312
    pypy3
    python27
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
    #helm
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
    #  vdhcoapp install --user (https://github.com/NixOS/nixpkgs/issues/112046)
    vdhcoapp
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
    isd
    loccount
    lazydocker
    rst2pdf
    go
    expect
    pbzip2
    gnome-firmware
    dysk
    manim
    manim-slides
    inputs.agenix.packages."${system}".default
    mailutils # for checking zed reports
    nil # for nix emacs lsp-mode
    rust-analyzer # for rust emacs lsp-mode
    # for testing ARC
    # kind # kubernetes
    # kubernetes-helm
    # kubectl
  ];
}
