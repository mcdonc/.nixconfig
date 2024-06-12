{ pkgs, nixos-hardware, ...}:

{
  imports = [
    "${nixos-hardware}/common/cpu/intel"
  ];
  hardware.opengl.extraPackages = with pkgs; [ intel-compute-runtime ];
  boot.kernelModules = [ "kvm-intel" ];
}
  
