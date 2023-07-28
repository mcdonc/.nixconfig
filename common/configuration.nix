{ config, pkgs, ... }:

{
  imports = [ ./cachix.nix ];

  # nix stuff
  system.stateVersion = "22.05";

  # see https://chattingdarkly.org/@lhf@fosstodon.org/110661879831891580
  system.activationScripts.diff = {
    supportsDryActivation = true;
    text = ''
      ${pkgs.nvd}/bin/nvd --nix-bin-dir=${pkgs.nix}/bin diff /run/current-system "$systemConfig"
    '';
  };

  nix.package = pkgs.nixUnstable;
  nix.extraOptions = ''
    experimental-features = nix-command flakes
    trusted-users = root @wheel
    sandbox = relaxed
  '';

  nix.settings = {
    tarball-ttl = 300;
    auto-optimise-store = true;
  };

  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };

  # NVIDIA requires nonfree
  nixpkgs.config.allowUnfree = true;
  nixpkgs.config.permittedInsecurePackages = [ "electron-12.2.3" ]; # etcher
  
  # Use GRUB, assume UEFI
  boot.loader.grub.enable = true;
  boot.loader.grub.devices = [ "nodev" ];
  boot.loader.grub.efiInstallAsRemovable = true;
  boot.loader.grub.efiSupport = true;
  boot.loader.grub.splashImage = ./grub/alwaysnix.png;
  boot.loader.grub.splashMode = "stretch"; # "normal"
  boot.loader.grub.useOSProber = true;
  boot.loader.timeout = 60;
  boot.kernelModules = [ "snd-seq" "snd-rawmidi" ];
  # copyKernels: "Using NixOS on a ZFS root file system might result in the
  # boot error external pointer tables not supported when the number of
  # hardlinks in the nix store gets very high.
  boot.loader.grub.copyKernels = true;

  ## obs
  boot.extraModulePackages = with config.boot.kernelPackages; [ v4l2loopback ];

  # realtime audio priority (initially for JACK2)
  security.pam.loginLimits = [
    {
      domain = "@audio";
      item = "memlock";
      type = "-";
      value = "unlimited";
    }
    {
      domain = "@audio";
      item = "rtprio";
      type = "-";
      value = "99";
    }
    {
      domain = "@audio";
      item = "nofile";
      type = "soft";
      value = "99999";
    }
    {
      domain = "@audio";
      item = "nofile";
      type = "hard";
      value = "99999";
    }
  ];

  # enable high precision timers if they exist (https://gentoostudio.org/?page_id=420)
  services.udev = {
    extraRules = ''
      KERNEL=="rtc0", GROUP="audio"
      KERNEL=="hpet", GROUP="audio"
    '';
  };

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

  # desktop stuff
  services.xserver.enable = true;
  #services.xserver.displayManager.gdm.enable = true;
  services.xserver.displayManager.sddm.enable = true;
  services.xserver.desktopManager.plasma5.enable = true;
  services.xserver.layout = "us";
  services.xserver.xkbOptions = "ctrl:nocaps,terminate:ctrl_alt_bksp";
  services.xserver.enableCtrlAltBackspace = true;
  services.xserver.dpi = 96;
  services.xserver.libinput.enable = true; # touchpad
  fonts.fonts = with pkgs; [ ubuntu_font_family ];

  # sound
  sound.enable = true;
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
  programs.dconf.enable = true;

  # printing
  services.printing.enable = true;
  services.avahi.enable = true;
  services.avahi.nssmdns = true;

  # all other services
  services.fwupd.enable = true;
  services.locate.enable = true;
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      PermitRootLogin = "no";
    };
  };
  services.tlp = {
    settings = {
      # only charge up to 80% of the battery capacity
      START_CHARGE_THRESH_BAT0 = "75";
      STOP_CHARGE_THRESH_BAT0 = "80";
    };
  };
  services.fstrim.enable = true;
  services.zfs.autoScrub.enable = true;
  services.zfs.autoScrub.interval = "quarterly";
  services.zfs.trim.enable = true;

  programs.steam.enable = true;

  # enable docker
  virtualisation.docker.enable = true;

  # default shell for all users
  users.defaultUserShell = pkgs.zsh;
  programs.zsh.enable = true;

  programs.ssh = {
    pubkeyAcceptedKeyTypes = [ "ssh-ed25519" "ssh-rsa" ];
    hostKeyAlgorithms = [ "ssh-ed25519" "ssh-rsa" ];
  };

  users.groups.nixconfig = { };

  environment.etc."vimrc".text = ''
    " get rid of maddening mouseclick-moves-cursor behavior
    set mouse=
    set ttymouse=
  '';

  # List software packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    vim_configurable
    wget
    (wrapOBS { plugins = with obs-studio-plugins; [ obs-backgroundremoval ]; })
    thermald
    powertop
    libsForQt5.kdeconnect-kde
    libsForQt5.krdc
    libsForQt5.breeze-gtk
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
    virtualbox
    (python310.withPackages (p:
      with p; [
        python310Packages.pyserial # for pico-w-go in vscode
        python310Packages.pyflakes # for emacs
        python310Packages.black # for cmdline and vscode
      ]))
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
    nixfmt
    wakeonlan
    r2211.olive-editor # use 0.1.2 (see flake.nix overlay-r2211)
    cachix
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
    vscode
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
    nvd # for nixos-rebuild diffing
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
  ];
}
