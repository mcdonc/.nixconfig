{ config, pkgs, home-manager, ... }:

let
  rbash = pkgs.runCommandNoCC "rbash-${pkgs.bashInteractive.version}" { } ''
    mkdir -p $out/bin
    ln -s ${pkgs.bashInteractive}/bin/bash $out/bin/rbash
  '';

  # XXX trying to simplify so I don't need all those dotfiles and to stop it
  # from sourcing global rcfiles; works interactively but not when sending
  # commands on ssh command line
  rbash-norc =
    pkgs.runCommandNoCC "rbash-norc-${pkgs.bashInteractive.version}" { } ''
      mkdir -p $out/bin
      cat << EOF > $out/bin/rbash-norc
      #!${pkgs.bashInteractive}/bin/bash
      export PATH=\$HOME/bin
      exec ${pkgs.bashInteractive}/bin/bash --norc --noprofile -r
      EOF
      chmod 755 $out/bin/rbash-norc
    '';

  homedir = "/var/lib/backup";

in
{
  # https://github.com/nix-community/home-manager/issues/4433
  home-manager.users.backup = { config, ... }: {
    home.stateVersion = "23.11";
    home.username = "backup";
    home.homeDirectory = homedir;

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
    home.file.".bash_login" = {
      executable = true;
      text = ''
        export PATH=$HOME/bin
      '';
    };
    # https://www.reddit.com/r/NixOS/comments/v0eak7/homemanager_how_to_create_symlink_to/
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
    home = homedir;
    group = "backup";
    shell = "${rbash}/bin/rbash";
    extraGroups = [ ];
    openssh = {
      # https://stackoverflow.com/a/50400836 ; prevent
      # ssh backup@optinix.local -t "bash --noprofile" via no-pty
      authorizedKeys.keys = [
        "no-port-forwarding,no-X11-forwarding,no-agent-forwarding,no-pty ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPIbkGiLOckZtVuWCBWZUtqIl3seeqlRHnb7e2sdCNHs chrism@optinix"
      ];
    };
  };

  users.groups.backup = { };

  services.sanoid = {
    enable = true;
    interval = "*:2,32"; # run this more often than syncoid (every 30 mins)
    datasets = {
      "NIXROOT/home" = {
        autoprune = true;
        autosnap = true;
        hourly = 1;
        daily = 1;
        weekly = 1;
        monthly = 1;
        yearly = 0;
      };
    };
    extraArgs = [ "--debug" ];
  };


  environment.systemPackages = with pkgs; [
    # used by zfs send/receive
    pv
    mbuffer
    lzop
    zstd
  ];

  system.activationScripts.zfsbackupuser = pkgs.lib.stringAfter [ "users" ]
    ''
     sudo zfs allow backup compression,hold,send,snapshot,mount,destroy NIXROOT/home
    ''
}
