{ config, pkgs, home-manager, ... }:

let
  restrictbackup = pkgs.writeShellScriptBin "restrictbackup" ''
      if [[ $SSH_ORIGINAL_COMMAND == zfs* ]];
      then
         `$SSH_ORIGINAL_COMMAND``
      else
         echo "Access denied: $SSH_ORIGINAL_COMMAND"
      fi
  '';

in {
  # Define a user account.
  users.users.backup = {
    isNormalUser = true;
    #shell = "/run/current-system/sw/bin/nologin";
    createHome = false;
    home = "/var/empty";
    extraGroups = [ ];
    openssh = {
      authorizedKeys.keys = [
        ''command="${restrictbackup}/bin/restrictbackup" ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINLuqK/tjXwfiMpOVw3Kk2N24BbEoY3jT4D66WvYGS0v chrism@thinknix512''
      ];
    };
  };

  services.sanoid = {
    enable = true;
    interval = "*:0/5";
    #interval = "hourly"; # run this hourly, run syncoid daily to prune ok
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
