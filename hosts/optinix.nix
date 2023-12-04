{ config, pkgs, lib, nixos-hardware, ... }:
{
  imports = [
    "${nixos-hardware}/common/cpu/intel"
    ../encryptedzfs.nix
    ../common.nix
  ];
  system.stateVersion = "23.11";

  networking.hostId = "0a2c6440b";
  networking.hostName = "optinix";

}
