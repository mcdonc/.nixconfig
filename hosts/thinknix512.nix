{
  config,
  lib,
  nixos-hardware,
  ...
}:

{
  imports = [
    ../users/chrism
    ./roles/workstation.nix
    "${nixos-hardware}/lenovo/thinkpad/p51"
    "${nixos-hardware}/common/pc/ssd"
    ./roles/pseries.nix
    #./roles/sessile.nix
    ./roles/encryptedzfs.nix
    ./roles/tlp.nix
    ./roles/dnsovertls/resolvedonly.nix
    ./roles/backupsource.nix
    ./roles/steam.nix
    #./roles/vmount.nix
    ./roles/proaudio.nix
  ];
  system.stateVersion = "22.05";
  networking.hostId = "deadbeef";
  networking.hostName = "thinknix512";

  hardware.nvidia.prime.offload.enable = lib.mkForce (
    !config.hardware.nvidia.prime.sync.enable
  );
  hardware.nvidia.prime.sync.enable = lib.mkForce false;

  # silence ACPI "errors" at boot shown before NixOS stage 1 output
  # (default is 4)
  boot.consoleLogLevel = 3;

}
