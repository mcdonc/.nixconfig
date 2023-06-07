{ config, pkgs, nixpkgs, nixpkgs-2211, ...}:

{

  hardware.nvidia.package = config.boot.kernelPackages.nvidiaPackages.production;
  hardware.nvidia.powerManagement.enable = true;
  
}


#   { config, pkgs, nixpkgs, nixpkgs-2211, ...}:

# let
#   oldpkgs = import  nixpkgs-2211{};
#   # We'll use this twice
#   pinnedKernelPackages = oldpkgs.linuxPackages_latest;

# in

# {
#   # allow nvidia drivers to be loaded 
#   nixpkgs.config.allowUnfree = true;

#   nixpkgs.config.packageOverrides = pkgs: {
#     # swap out all of the linux packages
#     linuxPackages_latest = pinnedKernelPackages;

#     # make sure x11 will use the correct package as well
#     nvidia_x11 = oldpkgs.nvidia_x11;
#   };

#   # line up your kernel packages at boot
#   boot.kernelPackages = pinnedKernelPackages;
# }

# { config, pkgs, nixpkgs, nixpkgs-2211, ... }:
# let version = "520.56.06";
# in {
#   hardware.nvidia.package =
#     config.boot.kernelPackages.nvidiaPackages.stable.overrideAttrs (old: {
#       src = builtins.fetchurl {
#         url =
#           "https://us.download.nvidia.com/XFree86/Linux-x86_64//NVIDIA-Linux-x86_64-${version}.run";
#         sha256 = "sha256:0iiw25ngfhd3nrlr0lc59wihcfb9ip8q9jj17p26wxnnpq04nrsi";
#       };d
     
#     });
# }
