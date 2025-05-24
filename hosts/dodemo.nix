{ lib, pkgs, nixpkgs, nixos-generators, system, ... }:

{
  imports = [
    "${nixpkgs}/nixos/modules/virtualisation/digital-ocean-config.nix"
    nixos-generators.nixosModules.all-formats
  ];

  networking.hostId = "bd246190";
  networking.hostName = "dodemo";
  system.stateVersion = "25.05";

  environment.systemPackages = with pkgs; [
    vim
    wget
    curl
  ];

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

  networking.firewall.enable = true;
  networking.firewall.allowedTCPPorts = [ 22 80 443 ];

  time.timeZone = "America/New_York";

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

  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      PermitRootLogin = "no";
    };
  };

  programs.git.enable = true;

  users.users.chrism = {
    isNormalUser = true;
    initialPassword = "pw321";
    extraGroups = [
      "wheel"
    ];
    openssh = {
      authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOLXUsGqUIEMfcXoIiiItmGNqOucJjx5D6ZEE3KgLKYV ednesia"
      ];
    };
  };
}
