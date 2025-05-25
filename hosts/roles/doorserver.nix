{ pkgs, lib, config, inputs, ... }:

let
  breakonthru = pkgs.python311Packages.buildPythonPackage rec {

    pname = "breakonthru";
    version = "0.0";
    pyproject = true;

    src = pkgs.fetchFromGitHub {
      owner = "mcdonc";
      repo = "breakonthru";
      rev = "956c1e2b18ae8b2471fe4305a262872bf4db27d9";
      sha256 = "sha256-sHiRmMtZG3Qhaoq+rMJ+K4kQKpmjbxsmygYaLMlFtpk=";
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
    production-ini-file = lib.mkOption {
      type = lib.types.str;
      description = "Path to the production.ini file";
      default = "/var/lib/doorserver/production.ini";
    };
    server-ini-file = lib.mkOption {
      type = lib.types.str;
      description = "Path to the server.ini file";
      default = "/var/lib/doorserver/server.ini";
    };
  };

  config = let
    cfg = config.services.doorserver;
    creds = [
      "DOORSERVER_WSSECRET_FILE:${cfg.wssecret-file}"
      "DOORSERVER_PASSWORDS_FILE:${cfg.passwords-file}"
      "DOORSERVER_DOORS_FILE:${cfg.doors-file}"
      "DOORSERVER_PRODUCTION_INI_FILE.ini:${cfg.production-ini-file}"
      "DOORSERVER_SERVER_INI_FILE.ini:${cfg.server-ini-file}"
    ];

    envs = [
      "DOORSERVER_WSSECRET_FILE=:%d/DOORSERVER_WSSECRET_FILE"
      "DOORSERVER_PASSWORDS_FILE=%d/DOORSERVER_PASSWORDS_FILE"
      "DOORSERVER_DOORS_FILE=%d/DOORSERVER_DOORS_FILE"
      "DOORSERVER_PRODUCTION_INI_FILE=%d/DOORSERVER_PRODUCTION_INI_FILE.ini"
      "DOORSERVER_SERVER_INI_FILE=%d/DOORSERVER_SERVER_INI_FILE.ini"
    ];

  in
    lib.mkIf cfg.enable {
      environment.systemPackages = [ pyenv-bin ];

      systemd.tmpfiles.rules = [
        "d /var/lib/doorserver 0755 root root -"
      ];

      systemd.services.doorserver-ui = {
        description = "Doorserver UI server";
        after = [ "network.target" ];
        wantedBy = [ "multi-user.target" ];
        script = ''
          secret=$(cat $CREDENTIALS_DIRECTORY/DOORSERVER_WSSECRET_FILE)
          export DOORSERVER_WSSECRET="$secret"
          exec ${pyenv}/bin/pserve "$DOORSERVER_PRODUCTION_INI_FILE"
        '';
        serviceConfig = {
          Restart = "always";
          RestartSec = "5s";
          User = "doorserver";
          Group = "doorserver";
          DynamicUser = true;
          LoadCredential = creds;
          Environment = envs;
        };
      };

      systemd.services.doorserver-websocket = {
        description = "Doorserver websocket server";
        after = [ "network.target" ];
        wantedBy = [ "multi-user.target" ];
        script = ''
          secret=$(cat $CREDENTIALS_DIRECTORY/DOORSERVER_WSSECRET_FILE)
          export DOORSERVER_WSSECRET="$secret"
          exec ${pyenv}/bin/doorserver "$DOORSERVER_SERVER_INI_FILE"
        '';
        serviceConfig = {
          Restart = "always";
          RestartSec = "5s";
          User = "doorserver";
          Group = "doorserver";
          DynamicUser = true;
          LoadCredential = creds;
          Environment = envs;
        };
      };
    };
}
