{ config, lib, pkgs, ... }:

{
  # can't use tlp if this is enabled
  services.power-profiles-daemon.enable = false;

  services.tlp = {
    enable = true;
    settings = {
      CPU_SCALING_GOVERNOR_ON_AC = "performance";
      # only charge up to 80% of the battery capacity
      START_CHARGE_THRESH_BAT0 = "75";
      STOP_CHARGE_THRESH_BAT0 = "80";
      # rtl8153 / tp-link ue330 quirk for USB ethernet
      USB_DENYLIST = "2357:0601 0bda:5411";
    };
  };

}
