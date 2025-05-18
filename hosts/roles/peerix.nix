{ lib, pkgs, inputs, ... }:
{
  #nixpkgs.overlays = [ inputs.peerix.overlay ];
  imports = [  inputs.peerix.nixosModules.peerix ];

  # Define a user account.
  users.users.peerix = {
    isSystemUser = true;
    group = "peerix";
  };

  users.groups.peerix = {};

  nix.settings.allowed-users = [ "peerix" ];

  services.peerix = {
    enable = true;
    privateKeyFile = "/etc/nixos/peerix-private";
    publicKeyFile = "/etc/nixos/peerix-public";
    publicKey = "peerix-keithmoon:s/DzPd1deGneuvQsCT1FzgyoXghuOtNt8pLDOM3qko0= peerix-thinknix50:ep42Cnw+QZj84FT5lb6pHOmKMIL+XWQViJBevVCZx1o=";
    user = "peerix";
  };

}
