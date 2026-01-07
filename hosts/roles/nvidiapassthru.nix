{
  config,
  pkgs,
  lib,
  nixos-hardware,
  inputs,
  options,
  ...
}:
{
  # for soliplex container gpu passthrough
  
  environment.systemPackages =  with pkgs; [
    cudatoolkit
    nvidia-container-toolkit
  ];

  hardware.nvidia-container-toolkit.enable = true;
  virtualisation.docker.enableNvidia = true; # deprecated but necessary
  virtualisation.docker.enable = true;
}
  
