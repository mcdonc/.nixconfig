{
  pkgs,
  pkgs-py36,
  pkgs-py37,
  pkgs-py39,
  pkgs-signal-7561,
  pkgs-unstable,
  inputs,
  system,
  config,
  ...
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

  findnixstorelinks = pkgs.writers.writePython3Bin "findnixstorelinks" { } (
    builtins.readFile ./bin/findnixstorelinks.py
  );

  python313WithPackages = (
    pkgs.python313.withPackages (
      p: with p; [
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
        pyyaml # for runcontainer
      ]
    )
  );

  syspython = pkgs.writeScriptBin "syspython" ''
    exec ${python313WithPackages}/bin/python $@
  '';

in
{
  nixpkgs.config.permittedInsecurePackages = [
     # unmaintained python
    "python-2.7.18.8"
    "python-2.7.18.12"
    "jitsi-meet-1.0.8792"
  ];

  environment.systemPackages =
    with pkgs;
    [
      age
      alsa-utils
      any-nix-shell
      asciiquarium
      banner
      bastet # tetris
      bat
      beep
      bintools # "strings"
      bottom
      btop
      cachix
      pkgs-unstable.claude-code
      cntr # for build debugging
      cowsay
      curl
      dig
      dua
      duf
      dysk
      envsubst
      ethtool
      expect
      fd
      file
      findnixstorelinks
      fio
      fortune
      gh
      gnumake
      gnutar
      go
      gzip
      html-tidy
      inetutils # for telnet
      inotify-tools
      inputs.agenix.packages."${system}".default
      iperf
      isd
      jq
      killall
      lha
      loccount
      lolcat
      lsof
      mailutils # for checking zed reports
      mbuffer
      mc
      minicom
      moon-buggy
      ncdu
      netcat
      net-tools
      nh
      nix-du
      nix-index # for nix-locate
      nix-output-monitor
      nix-tree
      nixfmt-rfc-style
      nixos-repl
      nmap
      openssl
      openvpn
      pbzip2
      pciutils
      pokete
      pre-commit
      progress
      pv
      python313WithPackages # order intentional; python313 will be first
      rig
      ripgrep
      shellcheck
      speedtest-cli
      swaks
      syspython
      tldr
      tmux
      tree
      unzip
      usbutils
      util-linux # wipefs
      wakeonlan
      wget
      wol
      xz
      zstd
      nixos-rebuild-ng
    ]
    ++ lib.optionals (!config.jawns.isworkstation) [
      vim
    ]
    ++ lib.optionals config.jawns.isworkstation [
      # for testing ARC
      # kind # kubernetes
      # kubernetes-helm
      # kubectl

      #distrho
      #glaxnimate # for kdenlive
      #helm
      #kaffeine
      #kdiff3
      #lsp-plugins # (too many plugins)
      #pkgs-olive.olive-editor # 0.1.2
      #quickgui
      #thonny
      #vcv-rack # (uncached)
      #zenity # undeclared dep of quickgui

      pkgs-py36.python36
      pkgs-py37.python37
      pkgs-py39.python38
      pkgs-py39.python39
      python310
      python311
      python312
      pypy3
      python27
      (wrapOBS {
        plugins = [ pkgs.obs-studio-plugins.obs-backgroundremoval ];
      })

      agebox
      airspy
      alsa-scarlett-gui
      alsa-utils # aplay
      antigravity
      appimage-run
      # ardour # broken under 25.11
      argyllcms
      audacity
      audiowaveform
      baobab
      bitwarden-desktop
      calf
      cheese
      clinfo
      cutecom
      discord
      distrobox
      dive # docker
      #dsd # for gprx dmr decoding, problems under 25.11
      #dsdcc # for gprx dmr decoding, problems under 25.11
      dtc # milkv
      dupe-krill
      dupeguru
      element-desktop
      fast-cli # wants chromium, wtf
      fdupes
      ffmpeg-full
      firefox
      freepats
      geekbench
      geteltorito
      gimp
      gitg
      github-desktop
      gitkraken
      gittyup
      gnome-boxes
      gnome-disk-utility
      gnome-firmware
      gnome-multi-writer
      gnupg
      google-chrome
      gparted
      gptfdisk # "sgdisk"
      gqrx
      graphviz
      gsmartcontrol
      gucharmap
      guitarix
      gxplugins-lv2
      hackrf
      handbrake
      hplip
      hydrogen
      imagemagick
      ipmitool
      kdePackages.breeze-gtk
      kdePackages.kdeconnect-kde
      kdePackages.kdenlive
      kdePackages.kmag
      kdePackages.konversation
      kdePackages.krdc
      lazydocker
      lazygit
      libreoffice
      lm_sensors
      localsend
      # manim # broken under 25.11
      # manim-slides
      meld
      mullvad-vpn
      #mplayer # broken under 25.11
      pkgs-unstable.mpv
      neofetch
      networkmanager-openvpn
      nickel
      nil # for nix emacs lsp-mode
      nrsc5
      nvidia-offload
      nvtopPackages.nvidia
      odin2
      pkgs-unstable.opencode
      #olive-editor # 0.2 # a dep has cmake problems in 25.11
      pico-sdk
      pinentry-tty # dep of gpg
      pkgs.vscode-fhs
      powertop
      protonvpn-gui
      qjackctl
      qjournalctl
      quickemu
      remmina
      #rhythmbox # broken under 25.11
      rnnoise-plugin
      #rpi-imager
      rshell
      rst2pdf
      ruby
      rust-analyzer # for rust emacs lsp-mode
      s-tui
      s3cmd
      sanoid
      screenkey
      sdcc
      # sdrangel # broken under 25.11
      setbfree
      sfizz
      signal-desktop
      slack
      smartmontools
      soapyairspy
      socat # for gprx dmr decoding
      sox # for play
      speech-denoiser
      speedtest-cli
      spice-gtk
      sqlite
      start-virsh
      stress-ng
      tap-plugins
      thermald
      thinkfan
      vdhcoapp # vdhcoapp install --user (https://github.com/NixOS/nixpkgs/issues/112046)
      vim-full
      virt-manager
      virt-viewer # for remote-viewer
      vlc
      #wireshark
      x42-avldrums
      x42-plugins
      xcalib
      xdotool
      xorg.xev
      xorg.xkbcomp
      xorg.xmodmap
      yt-dlp
      zam-plugins
      zgrviewer
      zoom-us
      zynaddsubfx
    ];
}
