{ pkgs, ... }:

{
  # see https://chattingdarkly.org/@lhf@fosstodon.org/110661879831891580
  # replace with nh
  # system.activationScripts.diff = {
  #   supportsDryActivation = true;
  #   text = ''
  #     ${pkgs.nvd}/bin/nvd --nix-bin-dir=${pkgs.nix}/bin diff \
  #          /run/current-system "$systemConfig"
  #   '';
  # };

  programs.nh = {
    enable = true;
    flake = "/etc/nixos";
  };

  nix = {
    settings = {
      tarball-ttl = 300;
      auto-optimise-store = true;
      experimental-features = "nix-command flakes";
      trusted-users = [
        "root"
        "@wheel"
      ];
    };
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 30d";
    };
  };

  nixpkgs.config.allowUnfree = true;

  environment.variables = {
    EDITOR = "emacs -nw";
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
    pubkeyAcceptedKeyTypes = [
      "ssh-ed25519"
      "ssh-rsa"
    ];
    hostKeyAlgorithms = [
      "ssh-ed25519"
      "ssh-rsa"
    ];
    startAgent = true; # starts a systemd user service
  };

  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      PermitRootLogin = "no";
    };
  };

  programs.htop.enable = true;
  programs.htop.settings = {
    show_program_path = 0;
    hide_kernel_threads = 1;
    hide_userland_threads = 1;
  };

  users.groups.nixconfig = { };

  # # enable nix-ld for pip and uv and friends
  # programs.nix-ld.enable = true;
  # programs.nix-ld.libraries = with pkgs; [
  #   stdenv.cc.cc.lib
  #   zlib # numpy
  # ];

}
