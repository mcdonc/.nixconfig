{ pkgs, pkgs-2511, config, ... }:

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
  python313WithPackages = (
    pkgs.python313.withPackages (p: with p; [ requests ])
  );
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
        pkgs-2511.fast-cli # XXX26.05 removed in nixpkgs 26.05 (unmaintainable)
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
    virtualHosts."localhost" = {
      locations."/klangk" = {
        return = "301 /klangk/";
      };
      # Hosted app proxy: nginx proxies directly to container port
      locations."~ ^/klangk/hosted/[^/]+/(\\d+)/(.*)" = {
        extraConfig = ''
          proxy_pass http://127.0.0.1:$1/$2$is_args$args;
          proxy_set_header Host $host;
          proxy_set_header X-Real-IP $remote_addr;
          proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
          proxy_set_header X-Forwarded-Proto $scheme;
          proxy_http_version 1.1;
        '';
      };
      locations."/klangk/" = {
        proxyPass = "http://localhost:8997/";
        proxyWebsockets = true;
        extraConfig = ''
          proxy_set_header Host $host;
          proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
          proxy_set_header X-Forwarded-Proto $scheme;
          proxy_set_header X-Forwarded-Host $host;
          proxy_set_header X-Real-IP $remote_addr;
          proxy_set_header X-Forwarded-Prefix /klangk;
          proxy_set_header Accept-Encoding "";

          # Rewrite base href for subpath hosting
          sub_filter '<base href="/" />' '<base href="/klangk/" />';
          sub_filter_once on;
          sub_filter_types text/html;
        '';
      };
      locations."/soliplex" = {
        return = "301 /soliplex/";
      };
      locations."/soliplex/" = {
        proxyPass = "http://localhost:8555/";
        proxyWebsockets = true;
        extraConfig = ''
          proxy_set_header Host $host;
          proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
          proxy_set_header X-Forwarded-Proto $scheme;
          proxy_set_header X-Forwarded-Host $host;
          proxy_set_header X-Real-IP $remote_addr;
          proxy_set_header X-Forwarded-Prefix /soliplex;
          proxy_set_header Accept-Encoding "";

          # Rewrite base href for subpath hosting
          sub_filter '<base href="/" />' '<base href="/soliplex/" />';
          sub_filter_once on;
          sub_filter_types text/html;
        '';
      };
    };
  };

  system.activationScripts.mkwwwdir = ''
    mkdir -p /var/www/speedtest
    chown nginx:nginx /var/www/speedtest
  '';

}
