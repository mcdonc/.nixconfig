{
  config,
  pkgs,
  lib,
  ...
}:
{
  # for soliplex container gpu passthrough
  
  environment.systemPackages =  with pkgs; [
    cudatoolkit
    nvidia-container-toolkit
  ];

  hardware.nvidia-container-toolkit.enable = true;
  virtualisation.docker.enableNvidia = true;
  # ^^ deprecated but necessary 4 solplx
  # see also https://github.com/NixOS/nixpkgs/pull/344188
  virtualisation.docker.enable = true;
}
  
