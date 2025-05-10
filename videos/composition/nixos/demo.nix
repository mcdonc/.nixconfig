# demo.nix
{ config, lib, pkgs, ... }:
{
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  users.users.chrism = {
    initialPassword = "123";
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    openssh = {
      authorizedKeys.keys = [
        "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCnLD+dQsKPhCV3eY0lMUP4fDrECI1Boe6PbnSHY+eqRpkA/Nd5okdyXvynWETivWsKdDRlT3gIVgEHqEv8s4lzxyZx9G2fAgQVVpBLk18G9wkH0ARJcJ0+RStXLy9mwYl8Bw8J6kl1+t0FE9Aa9RNtqKzpPCNJ1Uzg2VxeNIdUXawh77kIPk/6sKyT/QTNb5ruHBcd9WYyusUcOSavC9rZpfEIFF6ZhXv2FFklAwn4ggWzYzzSLJlMHzsCGmkKmTdwKijkGFR5JQ3UVY64r3SSYw09RY1TYN/vQFqTDw8RoGZVTeJ6Er/F/4xiVBlzMvxtBxkjJA9HLd8djzSKs8yf amnesia@amnesia"
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOLXUsGqUIEMfcXoIiiItmGNqOucJjx5D6ZEE3KgLKYV ednesia"
      ];
    };
  };
  networking.networkmanager.enable = true;
  services.openssh.enable = true;
  environment.systemPackages = with pkgs; [ vim-full git ];
  system.stateVersion = "25.05";
  security.sudo.wheelNeedsPassword = false;
  services.getty.autologinUser = "chrism";
  environment.shellInit = "export TERM=xterm-256color";
  virtualisation.diskSize = 61440;
  virtualisation.vmVariant = {
    virtualisation = {
      memorySize = 16384;
      cores = 4;
      diskSize = 61440;
    };
  };
  fileSystems."/" = {
    device = "/dev/vda";
    fsType = "ext4";
  };
  home-manager = {
    users.chrism = {
      home.stateVersion = "25.05";
      # cp -rL ~/.emacs.d /etc/nixos
      home.file.".emacs.d" = {
        # source = ./.emacs.d;
        source = ../../../users/.emacs.d;
        recursive = true;
      };
      programs.emacs.enable = true;
      programs.emacs.extraPackages = epkgs: [
        epkgs.nix-mode
        epkgs.nixpkgs-fmt
        epkgs.flycheck
        epkgs.json-mode
        epkgs.python-mode
        epkgs.auto-complete
        epkgs.web-mode
        epkgs.smart-tabs-mode
        epkgs.whitespace-cleanup-mode
        epkgs.flycheck-pyflakes
        epkgs.flycheck-pos-tip
        epkgs.nord-theme
        epkgs.nordless-theme
        epkgs.vscode-dark-plus-theme
        epkgs.doom-modeline
        epkgs.all-the-icons
        epkgs.all-the-icons-dired
        epkgs.magit
        epkgs.markdown-mode
        epkgs.markdown-preview-mode
        epkgs.gptel
        pkgs.emacs-all-the-icons-fonts
        epkgs.yaml-mode
        epkgs.multiple-cursors
        epkgs.dts-mode
        epkgs.rust-mode
        epkgs.nickel-mode
        epkgs.editorconfig
        epkgs.terraform-mode
      ];
    };
  };

  # security.polkit = {
  #   extraConfig = ''
  #     polkit.addRule(function(action, subject) {
  #         if (action.id == "org.freedesktop.systemd1.manage-units" ||
  #             action.id == "org.freedesktop.systemd1.manage-unit-files") {
  #             if (action.lookup("unit") == "poweroff.target") {
  #                 return polkit.Result.YES;
  #             }
  #         }
  #     });
  #   '';
  # };
  # networking = {
  #   interfaces.eth0.useDHCP = true;
  #   interfaces.br0.useDHCP = true;
  #   useDHCP = false;

  #   bridges = {
  #     br0 = {
  #       interfaces = [
  #         "eth0"
  #       ];
  #     };
  #   };
  # };
}
