{ pkgs, lib, config, inputs, ... }:

let
  breakonthru = pkgs.python311Packages.buildPythonPackage rec {

    pname = "breakonthru";
    version = "0.0";
    pyproject = true;

    src = pkgs.fetchFromGitHub {
      owner = "mcdonc";
      repo = "breakonthru";
      rev = "b1276370a09ec528d85f4096ce00e90b2064f952";
      sha256 = "sha256-pa8mYI+BIN/JMbkr0xaKr4dyicK2zsnWacDaFDPEDFQ=";
    };

    build-system = with pkgs.python311Packages; [
      setuptools
    ];

    dependencies = with pkgs.python311Packages; [
      setuptools
      plaster-pastedeploy
      pyramid
      pyramid-chameleon
      #pyramid-debugtoolbar
      waitress
      bcrypt
      websockets
      gpiozero
      pexpect
      setproctitle
      requests
      websocket-client
    ];
  };

  # why must i repeat this?
  pyenv = (
    pkgs.python311.withPackages (p:
      with p; [
        breakonthru
        setuptools
        plaster-pastedeploy
        pyramid
        pyramid-chameleon
        #pyramid-debugtoolbar
        waitress
        bcrypt
        websockets
        gpiozero
        pexpect
        setproctitle
        requests
        websocket-client
      ]
    )
  );

  pyenv-bin = pkgs.writeShellScriptBin "pyenv-bin" ''
    exec ${pyenv}/bin/python $@
  '';

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

      # these are taken care of by __init__ reading envvars itself
      #password_file = %(ENV_DOORSERVER_PASSWORDS_FILE)s
      #doors_file =  %(ENV_DOORSERVER_DOORS_FILE)s
      #websocket_url = %(ENV_DOORSERVER_WEBSOCKET_URL)s
      #doorsip = %(ENV_DOORSERVER_DOORSIP)s
      #secret = %(ENV_DOORSERVER_WSSECRET)s

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
    { environment.systemPackages = [ pyenv-bin ];} //

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
          exec ${pyenv}/bin/pserve /run/doorserver/production.ini
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
          exec ${pyenv}/bin/doorserver /run/doorserver/server.ini
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
