{ config, pkgs, ... }:

let
  zedtest = pkgs.writeShellScriptBin "zedtest" ''
    dd if=/dev/zero of=/tmp/sparse_file bs=1 count=0 seek=512M
    sudo zpool create zedtest /tmp/sparse_file
    sudo zpool scrub zedtest
    sudo zpool export zedtest
    rm /tmp/sparse_file
  '';
in
{
  environment.systemPackages = [
    zedtest
  ];

  nixpkgs.config.packageOverrides = pkgs: {
    zfs = pkgs.zfs.override {
      enableMail = true;
    };
  };

  services.zfs.zed.enableMail = true;
  services.zfs.zed.settings = {
    ZED_EMAIL_ADDR = [ "chrism@repoze.org" ];
    ZED_EMAIL_PROG = "${pkgs.mailutils}/bin/mail";
    ZED_EMAIL_OPTS = "-s '@SUBJECT@' -r chrism@repoze.org @ADDRESS@";
    ZED_NOTIFY_VERBOSE = true;
  };

}
