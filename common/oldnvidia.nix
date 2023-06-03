{ config, pkgs, nixpkgs, nixpkgs-2211, ...}:

let
  oldpkgs = import  nixpkgs-2211{};
  # We'll use this twice
  pinnedKernelPackages = oldpkgs.linuxPackages_latest;

in

{
  # allow nvidia drivers to be loaded 
  nixpkgs.config.allowUnfree = true;

  nixpkgs.config.packageOverrides = pkgs: {
    # swap out all of the linux packages
    linuxPackages_latest = pinnedKernelPackages;

    # make sure x11 will use the correct package as well
    nvidia_x11 = oldpkgs.nvidia_x11;
  };

  # line up your kernel packages at boot
  boot.kernelPackages = pinnedKernelPackages;
}
