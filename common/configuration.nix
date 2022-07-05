{ config, pkgs, ... }:

{
  imports = [
    ./home.nix
  ];

  # Enable experimental features
  nix = {
    package = pkgs.nixUnstable;
    extraOptions = "experimental-features = nix-command flakes";
  };

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

  # Enable the DontZap option (it is this, rather than the above that makes ctrl-alt-bs work)
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

  
# Runtime PM for port ata1 of PCI device: Intel Corporation Q170/Q150/B150/H170/H110/Z170/CM236 Chipset SATA Controller [AHCI Mode] /sys/bus/pci/devices/0000:00:17.0/ata1/power/control
# Runtime PM for PCI Device Intel Corporation 100 Series/C230 Series Chipset Family USB 3.0 xHCI Controller /sys/bus/pci/devices/0000:00:14.0/power/control
# Runtime PM for port ata3 of PCI device: Intel Corporation Q170/Q150/B150/H170/H110/Z170/CM236 Chipset SATA Controller [AHCI Mode] /sys/bus/pci/devices/0000:00:17.0/ata3/power/control
# Runtime PM for PCI Device Intel Corporation Q170/Q150/B150/H170/H110/Z170/CM236 Chipset SATA Controller [AHCI Mode] /sys/bus/pci/devices/0000:00:17.0/power/control
# Runtime PM for port ata4 of PCI device: Intel Corporation Q170/Q150/B150/H170/H110/Z170/CM236 Chipset SATA Controller [AHCI Mode] /sys/bus/pci/devices/0000:00:17.0/ata4/power/control
# Runtime PM for PCI Device Intel Corporation 100 Series/C230 Series Chipset Family Power Management Controller /sys/bus/pci/devices/0000:00:1f.2/power/control
# Runtime PM for PCI Device Intel Corporation CM238 Chipset LPC/eSPI Controller /sys/bus/pci/devices/0000:00:1f.0/power/control
# Runtime PM for PCI Device Intel Corporation 100 Series/C230 Series Chipset Family PCI Express Root Port #1 /sys/bus/pci/devices/0000:00:1c.0/power/control
# Runtime PM for port ata2 of PCI device: Intel Corporation Q170/Q150/B150/H170/H110/Z170/CM236 Chipset SATA Controller [AHCI Mode] /sys/bus/pci/devices/0000:00:17.0/ata2/power/control
# Runtime PM for PCI Device Realtek Semiconductor Co., Ltd. RTS525A PCI Express Card Reader /sys/bus/pci/devices/0000:3f:00.0/power/control
# Runtime PM for PCI Device Intel Corporation Xeon E3-1200 v6/7th Gen Core Processor Host Bridge/DRAM Registers /sys/bus/pci/devices/0000:00:00.0/power/control
# Runtime PM for PCI Device Intel Corporation 100 Series/C230 Series Chipset Family PCI Express Root Port #5 /sys/bus/pci/devices/0000:00:1c.4/power/control
# Runtime PM for PCI Device Intel Corporation 100 Series/C230 Series Chipset Family Thermal Subsystem /sys/bus/pci/devices/0000:00:14.2/power/control

# found via tlp-stat -e
# 17.0, 14.0, 1f.2, 1f.0, 1c.0, 3f:00.0, 00.0, 1c.4, 14.2
  # 17.0 sata controller, ahci
  # 14.0 USB controller, xhci_hcd
  # 1f.2 Memory controller, (no driver)
  # 1f.0 ISA bridge, (no driver)
  # 1c.0 PCI bridge, pcieport
  # 3f:00.0 nassigned class [ff00], rtsx_pci
  # 00.0 Host bridge, skl_uncore
  # 1c.4 PCI bridge, pcieport
  # 14.2 Signal processing controller, intel_pch_thermal

# services.tlp = {
  # settings = {

    # allow sleep to work

    # with AHCI_RUNTIME_PM_ON_AC/BAT set to defaults in battery mode, P51
    # can't resume from sleep.  P50 can' sleep.
    # DISK_DEVICES must be specified for AHCI_RUNTIME_PM
    # DISK_DEVICES = "nvme0n1 nvme1n1 sda sdb";
    # AHCI_RUNTIME_PM_ON_AC = "on";
    # AHCI_RUNTIME_PM_ON_BAT = "on";

    # with RUNTIME_PM_ON_BAT/AC set to defaults, P51 can't go to sleep (P50 can)
    #RUNTIME_PM_ON_AC = "on";
    #RUNTIME_PM_ON_BAT = "on";

    # the below is pointless
    #SATA_LINKPWR_ON_AC = "";
    #SATA_LINKPWR_ON_BAT = "";
    #RUNTIME_PM_DRIVER_DENYLIST = "mei_me nouveau radeon ahci xhci_hcd pcieport rtsx_pci skl_uncore intel_pch_thermal intel-lpss mei_hdcp mei";
    # memory controller, ISA bridge, host bridge, PCIe root port #5/#13,#3,#9 thermal subsys
    #RUNTIME_PM_DISABLE = "00:1f.2 00:1f.0 00:00.0 00:1c.4 00:1d.4 00:1c.2 00:1d.0 00:14.2";
  #    };
  #  };

  services.fstrim.enable = true;

  # default shell for all users
  users.defaultUserShell = pkgs.zsh;

  # Define a user account.
  users.users.chrism = {
    isNormalUser = true;
    initialPassword = "pw321";
    extraGroups = [ "wheel" "networkmanager" ];
    openssh = {
      authorizedKeys.keys = [ "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCnLD+dQsKPhCV3eY0lMUP4fDrECI1Boe6PbnSHY+eqRpkA/Nd5okdyXvynWETivWsKdDRlT3gIVgEHqEv8s4lzxyZx9G2fAgQVVpBLk18G9wkH0ARJcJ0+RStXLy9mwYl8Bw8J6kl1+t0FE9Aa9RNtqKzpPCNJ1Uzg2VxeNIdUXawh77kIPk/6sKyT/QTNb5ruHBcd9WYyusUcOSavC9rZpfEIFF6ZhXv2FFklAwn4ggWzYzzSLJlMHzsCGmkKmTdwKijkGFR5JQ3UVY64r3SSYw09RY1TYN/vQFqTDw8RoGZVTeJ6Er/F/4xiVBlzMvxtBxkjJA9HLd8djzSKs8yf amnesia@amnesia" ];
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
  ];

  fonts.fonts = with pkgs; [
    ubuntu_font_family
  ];

  # Disable the firewall altogether.
  networking.firewall.enable = false;

  programs.steam.enable = true;

  system.stateVersion = "22.05"; # Did you read the comment?

}
