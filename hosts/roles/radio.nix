{ pkgs, ... }:
{
  hardware.rtl-sdr.enable = true;
  services.udev.packages = [ pkgs.airspy ];
}
