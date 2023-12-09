{ config, pkgs, lib, nixos-hardware, options, ... }:

{
  imports = [
    "${nixos-hardware}/lenovo/thinkpad/p51"
    "${nixos-hardware}/common/pc/ssd"
    ./profiles/pseries.nix
    ./profiles/sessile.nix
    ./profiles/encryptedzfs.nix
    ./profiles/tlp.nix
    # targeting 535.129.03, 545.29.02 backlightrestore doesn't work
    ./profiles/oldnvidia.nix
    ./profiles/dnsovertls/resolvedonly.nix
    ./profiles/steam.nix
    ../common.nix
  ];
  system.stateVersion = "22.05";
  networking.hostId = "deadbeef";
  networking.hostName = "thinknix512";

  hardware.nvidia.prime.offload.enable = false;
  hardware.nvidia.prime.sync.enable = lib.mkForce true;

  # silence ACPI "errors" at boot shown before NixOS stage 1 output
  # (default is 4)
  boot.consoleLogLevel = 3;

  boot.zfs.extraPools = [ "b" ];

  # dont ask for "b/storage" credentials
  boot.zfs.requestEncryptionCredentials = lib.mkForce [ "NIXROOT" ];

  # don't run updatedb on /b
  services.locate.prunePaths = [ "/b" ];

  # https://github.com/NixOS/nixpkgs/blob/master/nixos/modules/services/backup/sanoid.nix

  services.syncoid = {
    enable = true;
    #interval = "*:0/1";
    interval = "daily"; # important that syncoid runs less often than sanoid
    commonArgs = [ "--debug" ];
    commands = {
      "thinknix512-home" = {
        source = "NIXROOT/home";
        target = "b/thinknix512-home";
        sendOptions = "w c";
      };
      # sudo zfs allow backup compression,hold,send,snapshot,mount,destroy NIXROOT/home
      "optinix-home" = {
        sshKey = "/var/lib/syncoid/backup.key";
        source = "backup@optinix.local:NIXROOT/home";
        target = "b/optinix-home";
        sendOptions = "w c";
        extraArgs = [ "--sshoption=StrictHostKeyChecking=off" ];
      };
    };
    localSourceAllow = options.services.syncoid.localSourceAllow.default
      ++ [ "mount" ];
    localTargetAllow = options.services.syncoid.localTargetAllow.default
      ++ [ "destroy" ];
  };

  services.sanoid = {
    enable = true;
    #interval = "*:0/5";
    interval = "hourly"; # run this hourly, run syncoid daily to prune ok
    datasets = {
      "NIXROOT/home" = {
        autoprune = true;
        autosnap = true;
        hourly = 0;
        daily = 1;
        weekly = 1;
        monthly = 1;
        yearly = 0;
      };
      "b/storage" = {
        autoprune = true;
        autosnap = true;
        hourly = 0;
        daily = 0;
        weekly = 2;
        monthly = 0;
        yearly = 0;
      };
      # https://github.com/jimsalterjrs/sanoid/wiki/Syncoid#snapshot-management-with-sanoid
      "b/thinknix512-home" = {
        autoprune = true;
        autosnap = false;
        hourly = 0;
        daily = 7;
        weekly = 4;
        monthly = 12;
        yearly = 0;
      };
      "b/optinix-home" = {
        autoprune = true;
        autosnap = false;
        hourly = 0;
        daily = 7;
        weekly = 4;
        monthly = 12;
        yearly = 0;
      };
    };
    extraArgs = [ "--debug" ];
  };

  environment.systemPackages = with pkgs; [
    # used by zfs send/receive
    pv
    mbuffer
    lzop
    zstd
  ];
  
}
