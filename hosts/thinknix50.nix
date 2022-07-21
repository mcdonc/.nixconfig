{ config, pkgs, lib, ... }:

let
  hw = fetchTarball
    "https://github.com/NixOS/nixos-hardware/archive/master.tar.gz";
in {
  imports = [
    (import "${hw}/lenovo/thinkpad/p50")
    ../common/pseries.nix
    ../common/encryptedzfs.nix
    ../common/configuration.nix
    ../common/rc505.nix
  ];
  networking.hostId = "f416c9cd";
  networking.hostName = "thinknix50";

  # doesn't work, but for in the future...
  #services.fprintd.enable = true;
  #services.fprintd.tod.enable = true;
  #services.fprintd.tod.driver = pkgs.libfprint-2-tod1-vfs0090;

  # override optimus default offload mode to deal with external monitor
  # hardware.nvidia.prime.offload.enable = lib.mkForce false;
  # hardware.nvidia.prime.sync.enable = true;
}

