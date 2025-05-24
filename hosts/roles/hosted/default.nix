{ config, pkgs, ... }:

{

  imports = [
    ./packages.nix
  ];

  jawns.isworkstation = false;

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
    };
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 30d";
    };
  };

  nixpkgs.config.allowUnfree = true;

  # restart faster
  systemd.extraConfig = ''
    DefaultTimeoutStopSec=10s
  '';

  networking.networkmanager.enable = true;
  networking.firewall.enable = true;

  time.timeZone = "America/New_York";

  hardware.enableAllFirmware = true;

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

  services.locate.enable = false;

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

}
