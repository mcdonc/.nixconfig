{ pkgs, lib, config, inputs, pkgs-unstable, ... }:

let
  breakonthru = (import ./breakonthru.nix) {
    inherit pkgs pkgs-unstable lib inputs;
  };
in

{
  options.services.doorserver = {
    enable = lib.mkOption {
      type = lib.types.bool;
      description = "Enable the doorserver services";
      default = false;
    };
    passwords-file = lib.mkOption {
      type = lib.types.str;
      description = "Path to the passwords file";
      default = "/var/lib/doorserver/passwords";
    };
    wssecret-file = lib.mkOption {
      type = lib.types.str;
      description = "Path to the wssecret file";
      default = "/var/lib/doorserver/wssecret";
    };
    doors-file = lib.mkOption {
      type = lib.types.str;
      description = "Path to the doors file";
      default = "/var/lib/doorserver/doors";
    };
    websocket-url = lib.mkOption {
      type = lib.types.str;
      description = "Websocket URL";
      default = "wss://lock802ws.repoze.org/";
    };
    doorsip = lib.mkOption {
      type = lib.types.str;
      description = "Door SIP";
      default = "sip:7001";
    };
    uiserver-port = lib.mkOption {
      type = lib.types.str;
      description = "Listen port for ui server";
      default = "6544";
    };
    wsserver-port = lib.mkOption {
      type = lib.types.str;
      description = "Listen port for websocket server";
      default = "8001";
    };
    http-scheme = lib.mkOption {
      type = lib.types.str;
      description = "WSGI http scheme";
      default = "http";
    };
  };

  config = let
    cfg = config.services.doorserver;
    creds = [
      "DOORSERVER_WSSECRET_FILE:${cfg.wssecret-file}"
      "DOORSERVER_PASSWORDS_FILE:${cfg.passwords-file}"
      "DOORSERVER_DOORS_FILE:${cfg.doors-file}"
    ];

    envs = [
      "DOORSERVER_WSSECRET_FILE=:%d/DOORSERVER_WSSECRET_FILE"
      "DOORSERVER_PASSWORDS_FILE=%d/DOORSERVER_PASSWORDS_FILE"
      "DOORSERVER_DOORS_FILE=%d/DOORSERVER_DOORS_FILE"
      "DOORSERVER_WEBSOCKET_URL=${cfg.websocket-url}"
      "DOORSERVER_DOORSIP=${cfg.doorsip}"
    ];

    production_ini = ''
      [app:main]
      use = egg:breakonthru

      pyramid.reload_templates = true
      pyramid.debug_authorization = false
      pyramid.debug_notfound = false
      pyramid.debug_routematch = false
      pyramid.default_locale_name = en

      ###
      # wsgi server configuration
      ###

      [server:main]
      use = egg:waitress#main
      listen = *:${cfg.uiserver-port}
      #url_scheme = ${cfg.http-scheme}
      trusted_proxy_headers = x-forwarded-for x-forwarded-host x-forwarded-proto x-forwarded-port
      trusted_proxy = 127.0.0.1

      ###
      # logging configuration
      # https://docs.pylonsproject.org/projects/pyramid/en/latest/narr/logging.html
      ###

      [loggers]
      keys = root, breakonthru

      [handlers]
      keys = console

      [formatters]
      keys = generic

      [logger_root]
      level = INFO
      handlers = console

      [logger_breakonthru]
      level = INFO
      handlers =
      qualname = breakonthru

      [handler_console]
      class = StreamHandler
      args = (sys.stderr,)
      level = NOTSET
      formatter = generic

      [formatter_generic]
      format = %(asctime)s %(levelname)-5.5s [%(name)s:%(lineno)s][%(threadName)s] %(message)s
    '';

    server_ini = ''
      # remainder of settings are passed in as envvars
      [doorserver]
      port = ${cfg.wsserver-port}
    '';

  in
    { environment.systemPackages = [ breakonthru.pyenv-bin ];} //

    lib.mkIf cfg.enable {

      # dir not created on nixos-rebuild, only at boot
      # systemd.tmpfiles.rules = [
      #   "d /run/doorserver 0755 doorserver doorserver -"
      # ];

      systemd.services.doorserver-ui = {
        description = "Doorserver UI server";
        after = [ "network.target" ];
        wantedBy = [ "multi-user.target" ];
        preStart = ''
mkdir -p /run/doorserver
cat > /run/doorserver/production.ini << EOF
${production_ini}
EOF
chown -R doorserver:doorserver /run/doorserver
        '';
        script = ''
          secret=$(cat $CREDENTIALS_DIRECTORY/DOORSERVER_WSSECRET_FILE)
          export DOORSERVER_WSSECRET="$secret"
          exec ${breakonthru.pyenv}/bin/pserve /run/doorserver/production.ini
        '';
        serviceConfig = {
          Restart = "always";
          RestartSec = "5s";
          User = "doorserver";
          Group = "doorserver";
          DynamicUser = true;
          LoadCredential = creds;
          Environment = envs;
          PermissionsStartOnly = true; # run preStart as root
        };
      };

      systemd.services.doorserver-websocket = {
        description = "Doorserver websocket server";
        after = [ "network.target" ];
        wantedBy = [ "multi-user.target" ];
        preStart = ''
mkdir -p /run/doorserver
cat > /run/doorserver/server.ini << EOF
${server_ini}
EOF
chown -R doorserver:doorserver /run/doorserver
'';
        script = ''
          secret=$(cat $CREDENTIALS_DIRECTORY/DOORSERVER_WSSECRET_FILE)
          export DOORSERVER_WSSECRET="$secret"
          exec ${breakonthru.pyenv}/bin/doorserver /run/doorserver/server.ini
        '';
        serviceConfig = {
          Restart = "always";
          RestartSec = "5s";
          User = "doorserver";
          Group = "doorserver";
          DynamicUser = true;
          LoadCredential = creds;
          Environment = envs;
          PermissionsStartOnly = true; # run preStart as root
        };
       };
    };
}
