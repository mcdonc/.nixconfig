{ config, pkgs, lib, nixos-hardware, ... }:
{
  imports = [
    "${nixos-hardware}/lenovo/thinkpad/p50"
    ../pseries.nix
    ../encryptedzfs.nix
    ../common.nix
  ];
  system.stateVersion = "22.05";

  networking.hostId = "f416c9cd";
  networking.hostName = "thinknix50";

  # doesn't work, but for in the future...
  #services.fprintd.enable = true;
  #services.fprintd.tod.enable = true;
  #services.fprintd.tod.driver = pkgs.libfprint-2-tod1-vfs0090;

  # override optimus default offload mode to deal with external monitor
  hardware.nvidia.prime.offload.enable = lib.mkForce true;
  # hardware.nvidia.prime.sync.enable = true;

}

