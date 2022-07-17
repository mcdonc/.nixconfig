{ config, pkgs, ... }:

{
  imports = [ ./home.nix ./cachix.nix ];

  # Enable experimental features
  #nix.package = pkgs.nixUnstable;
  #nix.extraOptions = ''
  #  experimental-features = nix-command flakes
  #'';

  nix.settings = { tarball-ttl = 300; };

  # Use GRUB, assume UEFI
  boot.loader.grub.enable = true;
  boot.loader.grub.devices = [ "nodev" ];
  boot.loader.grub.efiInstallAsRemovable = true;
  boot.loader.grub.efiSupport = true;
  boot.loader.grub.splashImage = ./grub/alwaysnix.png;
  boot.loader.grub.splashMode = "stretch"; # "normal"
  boot.loader.grub.useOSProber = true;
  boot.loader.timeout = 60;
  # copyKernels: "Using NixOS on a ZFS root file system might result in the boot error
  # external pointer tables not supported when the number of hardlinks in the nix
  # store gets very high.
  boot.loader.grub.copyKernels = true;

  networking.networkmanager.enable = true;

  # Set your time zone.
  time.timeZone = "America/New_York";

  # Select internationalisation properties.
  # i18n.defaultLocale = "en_US.UTF-8";
  # console = {
  #  font = "Lat2-Terminus16";
  #  keyMap = "us";
  #  useXkbConfig = true; # use xkbOptions in tty.
  #};

  # ZFS services
  services.zfs.autoScrub.enable = true;
  services.zfs.trim.enable = true;

  # Enable the X11 windowing system.
  services.xserver.enable = true;

  # Enable the Plasma 5 Desktop Environment.
  services.xserver.displayManager.sddm.enable = true;
  services.xserver.desktopManager.plasma5.enable = true;

  # Configure keymap in X11
  services.xserver.layout = "us";
  services.xserver.xkbOptions = "ctrl:nocaps,terminate:ctrl_alt_bksp";

  # Makes ctrl-alt-backspace work (requires above xkbOption for terminate too)
  services.xserver.enableCtrlAltBackspace = true;

  # Make the DPI the same in sync mode as in offload mode.
  services.xserver.dpi = 96;

  # NVIDIA requires nonfree
  nixpkgs.config.allowUnfree = true;

  # allow for fwupdmgr firmware update manager use
  services.fwupd.enable = true;

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # enable locate
  services.locate.enable = true;

  # Enable sound.
  sound.enable = true;
  hardware.pulseaudio.enable = true;

  # Enable bluetooth
  hardware.bluetooth.enable = true;

  # Enable touchpad support (enabled default in most desktopManager).
  services.xserver.libinput.enable = true;

  # Enable the OpenSSH daemon.
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

  # default shell for all users
  users.defaultUserShell = pkgs.zsh;

  # Define a user account.
  users.users.chrism = {
    isNormalUser = true;
    initialPassword = "pw321";
    extraGroups = [ "wheel" "networkmanager" ];
    openssh = {
      authorizedKeys.keys = [
        "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCnLD+dQsKPhCV3eY0lMUP4fDrECI1Boe6PbnSHY+eqRpkA/Nd5okdyXvynWETivWsKdDRlT3gIVgEHqEv8s4lzxyZx9G2fAgQVVpBLk18G9wkH0ARJcJ0+RStXLy9mwYl8Bw8J6kl1+t0FE9Aa9RNtqKzpPCNJ1Uzg2VxeNIdUXawh77kIPk/6sKyT/QTNb5ruHBcd9WYyusUcOSavC9rZpfEIFF6ZhXv2FFklAwn4ggWzYzzSLJlMHzsCGmkKmTdwKijkGFR5JQ3UVY64r3SSYw09RY1TYN/vQFqTDw8RoGZVTeJ6Er/F/4xiVBlzMvxtBxkjJA9HLd8djzSKs8yf amnesia@amnesia"
      ];
    };
  };

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
    firefox
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
    vlc
    google-chrome
    audacity
    #etcher
    gimp
    transmission-qt
    remmina
    baobab
    signal-desktop
    virtualbox
    python310
    xz
    libreoffice
    ffmpeg-full
    iperf
    python310Packages.pyflakes
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
    gptfdisk
  ];

  fonts.fonts = with pkgs; [ ubuntu_font_family ];

  # Disable the firewall altogether.
  networking.firewall.enable = false;

  programs.steam.enable = true;

  system.stateVersion = "22.05"; # Did you read the comment?

}
