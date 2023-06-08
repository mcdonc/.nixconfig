{ config, pkgs, nixpkgs, ...}:

 {

  hardware.nvidia.package = config.boot.kernelPackages.nvidiaPackages.stable;
  #hardware.nvidia.powerManagement.enable = true;

  # 6/7/2023 under 23.05: beta reports as 530.41.03, stable as 530.41.03, 
  # production as 525.116.04.  Use of production won't allow the computer
  # to sleep for more than, say, a minute.
}


# let
#   pinnedKernelPackages = pkgs.r2211.linuxPackages_latest;
#   x11Packages = pkgs.r2211.nvidia_x11;

# in

# {
#   # allow nvidia drivers to be loaded 
#   nixpkgs.config.allowUnfree = true;

#   nixpkgs.config.packageOverrides = pkgs: {
#     # swap out all of the linux packages
#     linuxPackages_latest = pinnedKernelPackages;

#     # make sure x11 will use the correct package as well
#     nvidia_x11 = x11Packages;
#   };

#   # line up your kernel packages at boot
#   boot.kernelPackages = pinnedKernelPackages;
# }

# let version = "520.56.06";
# in {
#   hardware.nvidia.package =
#     config.boot.kernelPackages.nvidiaPackages.production.overrideAttrs (old: {
#       src = builtins.fetchurl {
#         url =
#           "https://us.download.nvidia.com/XFree86/Linux-x86_64/NVIDIA-Linux-x86_64-${version}.run";
#         sha256 = "sha256:0iiw25ngfhd3nrlr0lc59wihcfb9ip8q9jj17p26wxnnpq04nrsi";
#       };
     
#     });
# }
