{ config, pkgs, lib, ... }:

{
  imports = [
    ./packages.nix
    ./sound.nix
    ./printing.nix
    ./display.nix
  ];

  jawns.isworkstation = true;

  # see https://chattingdarkly.org/@lhf@fosstodon.org/110661879831891580
  # (replace with nh)
  #system.activationScripts.diff = {
  #  supportsDryActivation = true;
  #  text = ''
  #    ${pkgs.nvd}/bin/nvd --nix-bin-dir=${pkgs.nix}/bin diff \
  #         /run/current-system "$systemConfig"
  #  '';
  #};

  programs.nh = {
    enable = true;
    flake = "/etc/nixos";
  };

  nix = {
    settings = {
      tarball-ttl = 300;
      auto-optimise-store = true;
      experimental-features = "nix-command flakes";
      trusted-users = [ "root" "@wheel" ];
    };
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 30d";
    };
  };

  nixpkgs.config.allowUnfree = true;

  # obs
  boot.extraModulePackages = with config.boot.kernelPackages; [ v4l2loopback ];

  # rtl8153 / tp-link ue330 quirk for USB ethernet, see
  # https://askubuntu.com/questions/1081128/usb-3-0-ethernet-adapter-not-working-ubuntu-18-04
  # disables link power management for this usb ethernet adapter; won't work
  # otherwise
  boot.kernelParams = [
    "usbcore.quirks=2357:0601:k,0bda:5411:k" # ethernet, hub
  ];

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

  environment.variables = {
    EDITOR = "vi";
  };

  i18n.defaultLocale = "en_US.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_US.UTF-8";
    LC_IDENTIFICATION = "en_US.UTF-8";
    LC_MEASUREMENT = "en_US.UTF-8";
    LC_MONEY = "en_US.UTF-8";
    LC_NAME = "en_US.UTF-8";
    LC_NUMERIC = "en_US.UTF-8";
    LC_PAPER = "en_US.UTF-8";
    LC_TIME = "en_US.UTF-8";
  };

  # default shell for all users
  users.defaultUserShell = pkgs.zsh;
  programs.zsh.enable = true;

  programs.ssh = {
    pubkeyAcceptedKeyTypes = [ "ssh-ed25519" "ssh-rsa" ];
    hostKeyAlgorithms = [ "ssh-ed25519" "ssh-rsa" ];
    startAgent = true; # starts a systemd user service
  };

  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      PermitRootLogin = "no";
    };
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

  virtualisation.docker.enable = true;

  programs.dconf.enable = true;

  services.fwupd.enable = true;
  services.locate.enable = false;

  # wireshark without sudo; note that still necessary to add
  # wireshark to systemPackages to get gui I think
  programs.wireshark.enable = true;

  #programs.direnv.enable = true;
  #programs.direnv.enableZshIntegration = true;

  programs.htop.enable = true;
  programs.htop.settings = {
    show_program_path = 0;
    hide_kernel_threads = 1;
    hide_userland_threads = 1;
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
}
