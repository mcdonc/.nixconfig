{ config, pkgs, home-manager, ... }:

{
  # Define a user account.
  users.users.backup = {
    isNormalUser = true;
    #initialPassword = "pw321";
    extraGroups = [ ];
    openssh = {
      authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINLuqK/tjXwfiMpOVw3Kk2N24BbEoY3jT4D66WvYGS0v chrism@thinknix512"
      ];
    };
  };

}
