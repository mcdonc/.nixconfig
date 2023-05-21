{ config, pkgs, lib, ... }:

let
  hw = fetchTarball
    "https://github.com/NixOS/nixos-hardware/archive/master.tar.gz";
in {
  imports = [
    (import "${hw}/lenovo/thinkpad/t420")
    ../common/tseries.nix
    ../common/encryptedzfs.nix
    ../common/configuration.nix
    ../common/rc505.nix
    ../common/home/chrism.nix
  ];
  networking.hostId = "f5836aae";
  networking.hostName = "thinknix420";
  # silence BIOS-related "errors" at boot shown before NixOS stage 1 output (default
  # is 4)
  boot.consoleLogLevel = 3;

}

