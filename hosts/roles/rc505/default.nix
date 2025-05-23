{ pkgs, ... }:

{
  # enable the Roland RC-505 as an ALSA device

  # pin the kernel so we don't need to keep building it
  boot.kernelPackages = pkgs.linuxPackagesFor (pkgs.linux_6_12.override {
    argsOverride = rec {
      src = pkgs.fetchurl {
        url = "mirror://kernel/linux/kernel/v6.x/linux-${version}.tar.xz";
        sha256 = "sha256-3wRqSJceQM4LLgA+flW2sefaKRISDrIW1dbIRQyc+C4=";
      };
      version = "6.12.30";
      modDirVersion = "6.12.30";
    };
  });

  # this pin is not specific enough
  # boot.kernelPackages = pkgs.linuxPackages_6_1;

  # NB: The date in uname -a is not the date the kernel was built. The kernel
  # is built with a non-now date. Specifically, it’s the most recent timestamp
  # on files in the source tarball. So it doesn’t change when you patch it.

  # patch the kernel
  boot.kernelPatches = [{
    name = "roland-rc505";
    patch = ./roland.patch;
  }];
}
