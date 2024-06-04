{ pkgs, ... }:

{
  # enable the Roland RC-505 as an ALSA device

  # pin the kernel so we don't need to keep building it
  boot.kernelPackages = pkgs.linuxPackagesFor (pkgs.linux_6_1.override {
    argsOverride = rec {
      src = pkgs.fetchurl {
        url = "mirror://kernel/linux/kernel/v6.x/linux-${version}.tar.xz";
        sha256 = "sha256-0VDS2dQWh3Zo2LVvdXWfFmFo0ZJBnu+qlC7WciXL7AY=";
      };
      version = "6.1.82";
      modDirVersion = "6.1.82";
    };
  });

  # this pin is not specific enough
  # boot.kernelPackages = pkgs.linuxPackages_6_1;

  # patch the kernel
  boot.kernelPatches = [{
    name = "roland-rc505";
    patch = ./roland.patch;
  }];
}
