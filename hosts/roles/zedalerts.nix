{ ... }:
{
  nixpkgs.config.packageOverrides = pkgs: {
    zfs = pkgs.zfs.override { enableMail = true; };
  };
  services.zfs.zed.settings.ZED_EMAIL_ADDR = [ "chrism" ];
  services.zfs.zed.settings.ZED_NOTIFY_VERBOSE = true;
}
