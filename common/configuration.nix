{ config, pkgs, ... }:

{
  imports = [ ./cachix.nix ];

  # nix stuff
  system.stateVersion = "22.05";

  nix.package = pkgs.nixUnstable;

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
  # copyKernels: "Using NixOS on a ZFS root file system might result in the boot error
  # external pointer tables not supported when the number of hardlinks in the nix
  # store gets very high.
  boot.loader.grub.copyKernels = true;

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

  # for audio plugins, stolen from musnix
  environment.variables = {
    DSSI_PATH =
      "$HOME/.dssi:$HOME/.nix-profile/lib/dssi:/run/current-system/sw/lib/dssi";
    LADSPA_PATH =
      "$HOME/.ladspa:$HOME/.nix-profile/lib/ladspa:/run/current-system/sw/lib/ladspa";
    LV2_PATH =
      "$HOME/.lv2:$HOME/.nix-profile/lib/lv2:/run/current-system/sw/lib/lv2";
    LXVST_PATH =
      "$HOME/.lxvst:$HOME/.nix-profile/lib/lxvst:/run/current-system/sw/lib/lxvst";
    VST_PATH =
      "$HOME/.vst:$HOME/.nix-profile/lib/vst:/run/current-system/sw/lib/vst";
    VST3_PATH =
      "$HOME/.vst3:$HOME/.nix-profile/lib/vst3:/run/current-system/sw/lib/vst3";
  };

  # enable high precision timers if they exist (https://gentoostudio.org/?page_id=420)
  services.udev = {
    extraRules = ''
      KERNEL=="rtc0", GROUP="audio"
      KERNEL=="hpet", GROUP="audio"
    '';
  };

  networking.networkmanager.enable = true;
  networking.firewall.enable = false;

  time.timeZone = "America/New_York";

  hardware.bluetooth.enable = true;

  # desktop stuff
  services.xserver.enable = true;
  #services.xserver.displayManager.gdm.enable = true;
  services.xserver.displayManager.sddm.enable = true;
  # failed attempt to enable wayland
  #services.xserver.displayManager.sddm.settings.Wayland.SessionDir = "${pkgs.plasma5Packages.plasma-workspace}/share/wayland-sessions";
  services.xserver.desktopManager.plasma5.enable = true;
  services.xserver.layout = "us";
  services.xserver.xkbOptions = "ctrl:nocaps,terminate:ctrl_alt_bksp";
  services.xserver.enableCtrlAltBackspace = true;
  services.xserver.dpi = 96;
  services.xserver.libinput.enable = true; # touchpad
  fonts.fonts = with pkgs; [ ubuntu_font_family ];

  # sound
  sound.enable = true;
  #hardware.pulseaudio.enable = true;
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
    passwordAuthentication = false;
    permitRootLogin = "no";
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
    obs-studio
    thermald
    powertop
    libsForQt5.kdeconnect-kde
    libsForQt5.krdc
    gnome.gnome-disk-utility
    openvpn
    unzip
    ripgrep
    bpytop
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
    heroic
    s-tui
    stress-ng
    usbutils
    nmap
    zoom-us
    konversation
    nixfmt
    wakeonlan
    /nix/store/4nq5wfa01vq6x00q8k777qhf47bp2wd4-olive-editor-0.1.2
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
  ];
}
