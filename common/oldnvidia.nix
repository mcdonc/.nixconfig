{ config, pkgs, nixpkgs, nixpkgs-2211, ...}:

let
  # We'll use this twice
  pinnedKernelPackages = nixpkgs-2211.linuxPackages_latest;

in

{
  # allow nvidia drivers to be loaded 
  nixpkgs.config.allowUnfree = true;

  nixpkgs.config.packageOverrides = pkgs: {
    # swap out all of the linux packages
    linuxPackages_latest = pinnedKernelPackages;

    # make sure x11 will use the correct package as well
    nvidia_x11 = nixpkgs-2211.nvidia_x11;
  };

  # line up your kernel packages at boot
  boot.kernelPackages = pinnedKernelPackages;
}
