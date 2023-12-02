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
in

{
  imports = [
    "${nixos-hardware}/lenovo/thinkpad/p51"
    ../pseries.nix
    ../encryptedzfs.nix
    ../sessile.nix
#    ../rc505
    ../common.nix
    ../oldnvidia.nix # targeting 535.129.03, 545.29.02 backlightrestore doesn't work
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

  # alternate encrypted dns... https://mdleom.com/blog/2020/03/04/caddy-nixos-part-2/#DNS-over-TLS

  # encrypt dns (both networking.nameservers and services.resolved)
  # networking.nameservers =
  #   [ "1.1.1.1#one.one.one.one" "1.0.0.1#one.one.one.one" ];

  # services.resolved = {
  #   # see https://github.com/NixOS/nixpkgs/blob/master/nixos/modules/system/boot/resolved.nix
  #   enable = true;
  #   dnssec = "true";
  #   domains = [ "~." ];
  #   fallbackDns = [ "1.1.1.1#one.one.one.one" "1.0.0.1#one.one.one.one" ];
  #   extraConfig = ''
  #     DNSOverTLS=true
  #     #MulticastDNS=false
  #   '';
  #   #llmnr = "false"; # let Avahi handle mDNS
  # };

  # let resolved handle mDNS
  #services.avahi.enable = lib.mkForce false;
  #services.avahi.nssmdns = lib.mkForce false;

  services.nginx = {
    enable = true;
    virtualHosts."192.168.1.212" = {
      root = "/var/www/speedtest";
    };
  };

  # https://www.kubuntuforums.net/forum/general/documentation/how-to-s/675259-sddm-and-multiple-monitors-x11-session-too-many-log-in-screens
  # services.xserver.displayManager.setupCommands = ''
  #  xrandr --output DP-3 --mode 3840x2160 --pos 0x0 --output DP-4 --off 
  # '';

}
