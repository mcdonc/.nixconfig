args@{
  config,
  lib,
  nixos-hardware,
  ...
}:

{
  imports = [
    ../users/chrism
    ./roles/workstation.nix
    "${nixos-hardware}/lenovo/thinkpad/p52"
    "${nixos-hardware}/common/pc/ssd"
    ./roles/pseries.nix
    ./roles/encryptedzfs.nix
    ./roles/tlp.nix
    ./roles/steam.nix
    ./roles/davinci-resolve/studio.nix
    ./roles/dns/resolved-tls.nix # cannot be enabled for tpm
    ./roles/backupsource.nix
    ./roles/tailscale
    ./roles/nvidiapassthru.nix
    #./roles/nix-serve-client.nix
    #./roles/rc505
    #./roles/sessile.nix
    # ./roles/vmount.nix  # no steam when this is enabled, but nec for dvresolve
    # (
    #   import ./roles/macos-ventura.nix (
    #     args // {mem="12G"; cores=4; enable=true;}
    #   )
    # )
  ];

  system.stateVersion = "22.05";

  # per-host settings
  networking.hostId = "e1e4a33b";
  networking.hostName = "thinknix52";

  hardware.nvidia.prime.offload.enable = lib.mkForce (
    !config.hardware.nvidia.prime.sync.enable
  );

  # sleep doesnt work in offload mode 01/07/2025 kernel 6.6 nvidia 565
  # confirmed 07/12/2025 in 25.05
  hardware.nvidia.prime.sync.enable = lib.mkForce true;

  # silence ACPI "errors" at boot shown before NixOS stage 1 output (default
  # is 4)
  boot.consoleLogLevel = 3;

}
