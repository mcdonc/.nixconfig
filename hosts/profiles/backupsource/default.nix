{ config, pkgs, home-manager, ... }:

{
  # Define a user account.
  users.users.backup = {
    isNormalUser = true;
    #shell = "/run/current-system/sw/bin/nologin";
    createHome = false;
    home = "/var/empty";
    extraGroups = [ ];
    openssh = {
      authorizedKeys.keys = [
        ''command = "zfs" ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINLuqK/tjXwfiMpOVw3Kk2N24BbEoY3jT4D66WvYGS0v chrism@thinknix512''
      ];
    };
  };

  services.sanoid = {
    enable = true;
    interval = "*:0/30";
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
