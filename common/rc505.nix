{pkgs, ...}:

{
  # enable the Roland RC-505 as an ALSA device
  boot.kernelPackages = pkgs.linuxPackages_5_15;
  boot.kernelPatches = [{
    name = "roland-rc505";
    patch = ./roland.patch;
  }];
}
