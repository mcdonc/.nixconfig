{ config, pkgs, lib, nixos-hardware, options, ... }:

{
  imports = [
    ../users/chrism
    "${nixos-hardware}/lenovo/thinkpad/p51"
    "${nixos-hardware}/common/pc/ssd"
    ./roles/pseries.nix
    ./roles/sessile.nix
    ./roles/encryptedzfs.nix
    ./roles/tlp.nix
    # targeting 535.129.03, 545.29.02 backlightrestore doesn't work
    ./roles/dnsovertls/resolvedonly.nix
    ./roles/steam.nix
    ./roles/vmount.nix
    ../common.nix
  ];
  system.stateVersion = "22.05";
  networking.hostId = "deadbeef";
  networking.hostName = "thinknix512";

  hardware.nvidia.prime.offload.enable = lib.mkForce true;
  hardware.nvidia.prime.sync.enable = lib.mkForce false;

  # silence ACPI "errors" at boot shown before NixOS stage 1 output
  # (default is 4)
  boot.consoleLogLevel = 3;

  services.sanoid = {
    enable = true;
    interval = "*:2,32"; # run this more often than syncoid (every 30 mins)
    datasets = {
      "NIXROOT/home" = {
        autoprune = true;
        autosnap = true;
        hourly = 1;
        daily = 1;
        weekly = 1;
        monthly = 1;
        yearly = 0;
      };
    };
    extraArgs = [ "--debug" ];
  };

}
