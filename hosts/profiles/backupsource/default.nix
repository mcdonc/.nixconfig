{ config, pkgs, home-manager, ... }:

let
  restrictbackup = pkgs.stdenv.mkDerivation {
    name = "restrictbackup";
    dontUnpack = true;
    installPhase = "install -Dm755 ${./restrictbackup.py} $out/bin/restrictbackup";
    buildInputs = [ pkgs.python311 ];
  };
 
in {
  # Define a user account.
  users.users.backup = {
    isSystemUser = true;
    createHome = false;
    home = "/var/empty";
    group = "backup";
    shell = pkgs.bashInteractive;
    extraGroups = [ ];
    openssh = {
      authorizedKeys.keys = [
        ''command="${restrictbackup}/bin/restrictbackup" ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINLuqK/tjXwfiMpOVw3Kk2N24BbEoY3jT4D66WvYGS0v chrism@thinknix512''
      ];
    };
  };

  users.groups.backup = {};

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

  environment.systemPackages = with pkgs; [
    # used by zfs send/receive
    pv
    mbuffer
    lzop
    zstd
  ];

}
