{ config, pkgs, lib, nixos-hardware, options, ... }:

let
  fastlog = pkgs.stdenv.mkDerivation {
    name = "fastlog";
    dontUnpack = true;
    installPhase = "install -Dm755 ${../etc/fastlog.py} $out/bin/fastlog";
  };
  fasthtml = pkgs.stdenv.mkDerivation {
    name = "fasthtml";
    dontUnpack = true;
    installPhase = "install -Dm755 ${../etc/fasthtml.py} $out/bin/fasthtml";
  };

in {
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

  systemd.services.speedtest = {
    serviceConfig.Type = "oneshot";
    path = with pkgs; [ fastlog fasthtml fast-cli python311 ];
    script = ''
      #!/bin/sh
      fastlog
      fasthtml
    '';
  };

  systemd.timers.speedtest = {
    wantedBy = [ "timers.target" ];
    partOf = [ "speedtest.service" ];
    timerConfig = {
      # every two hours
      OnCalendar = "*-*-* 00,02,04,06,08,10,12,14,16,18,20,22:00:00";
      #OnCalendar = "*:0/5";
      Unit = "speedtest.service";
    };
  };

  services.nginx = {
    enable = true;
    virtualHosts."192.168.1.212" = { root = "/var/www/speedtest"; };
  };

  # https://www.kubuntuforums.net/forum/general/documentation/how-to-s/675259-sddm-and-multiple-monitors-x11-session-too-many-log-in-screens
  # services.xserver.displayManager.setupCommands = ''
  #  xrandr --output DP-3 --mode 3840x2160 --pos 0x0 --output DP-4 --off 
  # '';

}
