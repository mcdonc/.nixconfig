{ pkgs, lib, ... }:

{
  # enable the Roland RC-505 as an ALSA device

  # pin the kernel so we don't need to keep building it
  boot.kernelPackages = pkgs.linuxPackagesFor (pkgs.linux_6_1.override {
    argsOverride = rec {
      src = pkgs.fetchurl {
        url = "mirror://kernel/linux/kernel/v6.x/linux-${version}.tar.xz";
        sha256 = "sha256-qH4kHsFdU0UsTv4hlxOjdp2IzENrW5jPbvsmLEr/FcA=";
      };
      version = "6.1.55";
      modDirVersion = "6.1.55";
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
