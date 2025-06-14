{ config, ... }:

{
  nixpkgs.config.packageOverrides = pkgs: {
    zfs = pkgs.zfs.override {
      enableMail = true;
    };
  };
  services.zfs.zed.settings = {
    ZED_EMAIL_ADDR = [ "chrism@repoze.org" ];
    ZED_EMAIL_OPTS = "-s '@SUBJECT@' -r noreply@repoze.org @ADDRESS@";
    ZED_NOTIFY_VERBOSE = true;
  };

}
