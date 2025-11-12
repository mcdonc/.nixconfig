{ pkgs, config, ... }:

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
  numchannels = pkgs.stdenv.mkDerivation {
    name = "numchannels";
    dontUnpack = true;
    installPhase = "install -Dm755 ${./numchannels.py} $out/bin/numchannels";
  };
  python313WithPackages = (pkgs.python313.withPackages (p: with p; [requests]));
in
{
  age.secrets."netgear-cm1200-authorization" = {
    file = ../../../secrets/netgear-cm1200-authorization.age;
    mode = "600";
  };

  systemd.services.speedtest =
    let
      secretfile = config.age.secrets."netgear-cm1200-authorization".path;
    in
      {
        serviceConfig = {
          Type = "oneshot";
          LoadCredential = [
            "NETGEAR_CM1200_AUTHORIZATION:${secretfile}"
          ];
        };
        path = with pkgs; [
          fastlog
          fasthtml
          fast-cli
          numchannels
          python313WithPackages
        ];
        script = ''
          #!/bin/sh
          export MODEMSECRET=$(cat "$CREDENTIALS_DIRECTORY/NETGEAR_CM1200_AUTHORIZATION")
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
    virtualHosts."192.168.1.110" = {
      root = "/var/www/speedtest";
    };
  };

  system.activationScripts.mkwwwdir = ''
    mkdir -p /var/www/speedtest
    chown nginx:nginx /var/www/speedtest
  '';

}
