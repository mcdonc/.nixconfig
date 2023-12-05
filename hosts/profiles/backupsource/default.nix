{ config, pkgs, home-manager, ... }:

let
  rbash = pkgs.runCommandNoCC "rbash-${pkgs.bashInteractive.version}" { } ''
    mkdir -p $out/bin
    ln -s ${pkgs.bashInteractive}/bin/bash $out/bin/rbash
  '';

in {
  # https://github.com/nix-community/home-manager/issues/4433
  home-manager.users.backup = { config, ... }: {
    home.stateVersion = "23.11";
    home.username = "backup";
    home.homeDirectory = "/home/backup";

    home.file.".bash_profile" = {
      executable = true;
      text = ''
        export PATH=$HOME/bin
      '';
    };
    home.file.".bashrc" = {
      executable = true;
      text = ''
        export PATH=$HOME/bin
      '';
    };
    home.file.".profile" = {
      executable = true;
      text = ''
        export PATH=$HOME/bin
      '';
    };
    # https://www.reddit.com/r/NixOS/comments/v0eak7/homemanager_how_to_create_symlink_to/
    home.file."bin/ls".source =
      config.lib.file.mkOutOfStoreSymlink "${pkgs.coreutils}/bin/ls";
    home.file."bin/lzop".source =
      config.lib.file.mkOutOfStoreSymlink "${pkgs.lzop}/bin/lzop";
    home.file."bin/mbuffer".source =
      config.lib.file.mkOutOfStoreSymlink "${pkgs.mbuffer}/bin/mbuffer";
    home.file."bin/pv".source =
      config.lib.file.mkOutOfStoreSymlink "${pkgs.pv}/bin/pv";
    home.file."bin/zfs".source =
      config.lib.file.mkOutOfStoreSymlink "${pkgs.zfs}/bin/zfs";
    home.file."bin/zpool".source =
      config.lib.file.mkOutOfStoreSymlink "${pkgs.zfs}/bin/zpool";
    home.file."bin/zstd".source =
      config.lib.file.mkOutOfStoreSymlink "${pkgs.zstd}/bin/zstd";
  };

  # Define a user account.
  users.users.backup = {
    isSystemUser = true;
    createHome = true;
    home = "/home/backup";
    group = "backup";
    shell = "${rbash}/bin/rbash";
    extraGroups = [ ];
    openssh = {
      # https://stackoverflow.com/a/50400836 ; prevent
      # ssh backup@optinix.local -t "bash --noprofile" via no-pty
      authorizedKeys.keys = [
        "no-port-forwarding,no-X11-forwarding,no-agent-forwarding,no-pty ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINLuqK/tjXwfiMpOVw3Kk2N24BbEoY3jT4D66WvYGS0v chrism@thinknix512"
      ];
    };
  };

  users.groups.backup = { };

  services.sanoid = {
    enable = true;
    #interval = "*:0/5";
    interval = "hourly"; # run this hourly, run syncoid daily to prune ok
    datasets = {
      "NIXROOT/home" = {
        autoprune = true;
        autosnap = true;
        hourly = 0;
        daily = 1;
        weekly = 1;
        monthly = 1;
        yearly = 0;
      };
    };
    extraArgs = [ "--debug" ];
  };

}
