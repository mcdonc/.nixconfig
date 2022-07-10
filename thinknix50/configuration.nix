{ config, pkgs, lib, ... }:

let
  hwfork = fetchTarball "https://github.com/mcdonc/nixos-hardware/archive/pseries-additions.tar.gz";
in
{
  imports = [
    (import "${hwfork}/lenovo/thinkpad/p50")
    ../common/pseries.nix
    ../common/encryptedzfs.nix
    ../common/configuration.nix
  ];
  networking.hostId = "f416c9cd";
  networking.hostName = "thinknix50";
  networking.useDHCP = lib.mkForce true;

  #services.fprintd.enable = true;
  #services.fprintd.tod.enable = true;
  #services.fprintd.tod.driver = pkgs.libfprint-2-tod1-vfs0090;
  
  # override optimus default offload mode to deal with external monitor
  # hardware.nvidia.prime.offload.enable = lib.mkForce false;
  # hardware.nvidia.prime.sync.enable = true;
}


