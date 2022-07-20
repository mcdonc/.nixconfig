{pkgs, lib, ...}:

{
  # enable the Roland RC-505 as an ALSA device
  boot.kernelPackages = pkgs.linuxPackagesFor (pkgs.linux_5_15.override {
    argsOverride = rec {
      src = pkgs.fetchurl {
            url = "mirror://kernel/linux/kernel/v5.x/linux-${version}.tar.xz";
            sha256 = "sha256-Hva9UItsOvO+8tWzN+RHclTbooTHnjKao4+XY647/cw=";
      };
      version = "5.15.55";
      modDirVersion = "5.15.55";
      };
  });
  # boot.kernelPackages = pkgs.linuxPackages_5_15;
  boot.kernelPatches = [{
    name = "roland-rc505";
    patch = ./roland.patch;
  }];
}
