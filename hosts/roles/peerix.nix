{ lib, pkgs, inputs, ... }:
{
  imports = [  inputs.peerix.nixosModules.peerix ];

  # warning: binary cache 'http://127.0.0.1:12304' is for Nix stores with prefix 'Nix::Store::getStoreDir', not '/nix/store'
  # https://github.com/cid-chan/peerix/issues/9

  users.users.peerix = {
    isSystemUser = true;
    group = "peerix";
  };

  users.groups.peerix = {};

  nix.settings.allowed-users = [ "peerix" ];

  # nix-store --generate-binary-cache-key "peerix-$(hostname -s)" peerix-private peerix-public
  # journalctl -f -u peerix.service

  services.peerix = {
    enable = true;
    privateKeyFile = "/etc/nixos/peerix-private";
    publicKeyFile = "/etc/nixos/peerix-public";
    publicKey = "peerix-keithmoon:s/DzPd1deGneuvQsCT1FzgyoXghuOtNt8pLDOM3qko0= peerix-thinknix50:ep42Cnw+QZj84FT5lb6pHOmKMIL+XWQViJBevVCZx1o=";
    user = "peerix";
  };

}
