{ config, pkgs, lib, nixos-hardware, options, ... }:

{
  imports = [
    "${nixos-hardware}/lenovo/thinkpad/p51"
    ../pseries.nix
    ../encryptedzfs.nix
    ../sessile.nix
#    ../rc505
    ../common.nix
  ];
  system.stateVersion = "22.05";

  boot.zfs.extraPools = [ "b" ];

  # dont ask for "b/storage" credentials
  boot.zfs.requestEncryptionCredentials = lib.mkForce [ "NIXROOT" ];

  # Sep 17 00:00:05 thinknix512 sanoid[2534870]: INFO: pruning b/thinknix512-home@autosnap_2023-09-05_04:00:25_daily ...
  # Sep 17 00:00:06 thinknix512 sanoid[2534870]: INFO: deferring pruning of b/thinknix512-home@autosnap_2023-09-05_04:00:25_daily - b/thinknix512-home is currently in zfs send or receive.

  # https://github.com/NixOS/nixpkgs/blob/master/nixos/modules/services/backup/sanoid.nix

  services.syncoid = {
    enable = true;
    interval = "daily"; # important that syncoid runs less often than sanoid
    commands = {
      "NIXROOT/home" = {
        target = "b/thinknix512-home";
        sendOptions = "w c";
        extraArgs = [ "--debug" ];
      };
    };
    localSourceAllow = options.services.syncoid.localSourceAllow.default
      ++ [ "mount" ];
    localTargetAllow = options.services.syncoid.localTargetAllow.default
      ++ [ "destroy" ];
  };

  services.sanoid = {
    enable = true;
    #interval = "*:0/1";
    interval = "hourly"; # run this hourly, run syncoid daily to prune ok
    datasets = {
      "NIXROOT/home" = {
        autoprune = true;
        autosnap = true;
        daily = 1;
        weekly = 1;
        monthly = 1;
        yearly = 0;
        hourly = 0;
      };
      # https://github.com/jimsalterjrs/sanoid/wiki/Syncoid#snapshot-management-with-sanoid
      "b/thinknix512-home" = {
        autoprune = true;
        autosnap = false;
        daily = 7;
        weekly = 4;
        monthly = 12;
        yearly = 0;
        hourly = 0;
      };
    };
    extraArgs = [ "--debug" ];
  };

  services.locate.prunePaths = [ "/b" ];

  networking.hostId = "deadbeef";
  networking.hostName = "thinknix512";

  hardware.nvidia.prime.offload.enable = false;
  hardware.nvidia.prime.sync.enable = lib.mkForce true;

  # silence ACPI "errors" at boot shown before NixOS stage 1 output (default
  # is 4)
  boot.consoleLogLevel = 3;

  # why must I do this?  I have no idea.  But if I don't, swnix pauses then
  # "fails" (really just prints an error) when it switches configurations.
  systemd.services.NetworkManager-wait-online.enable = false;

  #services.cachix-agent.enable = true;
}
