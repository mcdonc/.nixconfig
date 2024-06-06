{ pkgs, ... }:

let

  fastlog = pkgs.stdenv.mkDerivation {
    name = "fastlog";
    dontUnpack = true;
    installPhase = "install -Dm755 ${./fastlog.py} $out/bin/fastlog";
  };
  fasthtml = pkgs.stdenv.mkDerivation {
    name = "fasthtml";
    dontUnpack = true;
    installPhase = "install -Dm755 ${./fasthtml.py} $out/bin/fasthtml";
  };

in
{
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

}
