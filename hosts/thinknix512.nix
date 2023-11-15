{ config, pkgs, lib, nixos-hardware, options, ... }:

let
  fastlog = pkgs.stdenv.mkDerivation {
    name = "fastlog";
    dontUnpack = true;
    installPhase = "install -Dm755 ${../etc/fastlog.py} $out/bin/fastlog";
  };
in

{
  imports = [
    "${nixos-hardware}/lenovo/thinkpad/p51"
    ../pseries.nix
    ../encryptedzfs.nix
    ../sessile.nix
    ../rc505
    ../common.nix
  ];
  system.stateVersion = "22.05";

  boot.zfs.extraPools = [ "b" ];

  # dont ask for "b/storage" credentials
  boot.zfs.requestEncryptionCredentials = lib.mkForce [ "NIXROOT" ];

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

  # # pixiecore quick xyz --dhcp-no-bind
  # services.pixiecore = {
  #   enable = true;
  #   openFirewall = true;
  #   dhcpNoBind = true;
  #   kernel = "https://boot.netboot.xyz";
  #   port = 98; # default is 80
  # };

  #services.cachix-agent.enable = true;

  systemd.services.speedtest = {
    serviceConfig.Type = "oneshot";
    path = with pkgs; [ fastlog fast-cli python311 ];
    script = ''
      #!/bin/sh
      fastlog
    '';
  };

  systemd.timers.speedtest = {
    wantedBy = [ "timers.target" ];
    partOf = [ "speedtest.service" ];
    timerConfig = {
      # every four hours
      OnCalendar = "*-*-* 00,04,08,12,16,20:00:00";
      #OnCalendar = "*:0/5";
      Unit = "speedtest.service";
    };
  };

}
