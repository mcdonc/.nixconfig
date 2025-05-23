{ nixos-hardware, ...}:

{
  imports = [
    "${nixos-hardware}/common/cpu/intel"
  ];
  boot.kernelModules = [ "kvm-intel" ]; # incompatible with virtualbox
}
  
