{ config, pkgs, lib, nixos-hardware, ... }:
{
  imports = [
    "${nixos-hardware}/lenovo/thinkpad/p50"
    ../common/configuration.nix
    ../common/pseries.nix
    ../common/encryptedzfs.nix
    ../common/configuration.nix
#    ../common/oldnvidia.nix
#    ../common/rc505.nix
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

  # why must I do this?  I have no idea.  But if I don't, swnix pauses then "fails"
  # (really just prints an error) when it switches configurations.
  systemd.services.NetworkManager-wait-online.enable = false;
}

