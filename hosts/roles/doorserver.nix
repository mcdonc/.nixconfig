{ pkgs, lib, config, inputs, ... }:

let
  breakonthru = pkgs.python311Packages.buildPythonPackage rec {

    pname = "breakonthru";
    version = "0.0";
    pyproject = true;

    src = pkgs.fetchFromGitHub {
      owner = "mcdonc";
      repo = "breakonthru";
      rev = "1b903feb6ff28e5d45f213fff94cb00523d0be11";
      sha256 = "sha256-uTSXv5/36H8CSeBVbisvbfVmdYjAt03lfyBIILjSq0w=";
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
  environment.systemPackages = [ pyenv-bin ];
  systemd.tmpfiles.rules = [
    "d /var/lib/doorserver 0755 root root -"
  ];

  systemd.services.doorserver-ui = {
    description = "Doorserver UI server";
    after = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];
    script = ''
      export DOORSERVER_WSSECRET="$CREDENTIALS_DIRECTORY/DOORSERVER_WSSECRET"
      exec ${pyenv}/bin/pserve /var/lib/doorserver/production.ini
    '';
    serviceConfig = {
      Restart = "always";
      RestartSec = "5s";
      User = "doorserver";
      Group = "doorserver";
      DynamicUser = true;
      LoadCredential = "DOORSERVER_WSSECRET:/var/lib/doorserver/wssecret";
    };
  };

  systemd.services.doorserver-websocket = {
    description = "Doorserver websocket server";
    after = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];
    script = ''
      export DOORSERVER_WSSECRET="$CREDENTIALS_DIRECTORY/DOORSERVER_WSSECRET"
      exec ${pyenv}/bin/doorserver /var/lib/doorserver/server.ini
    '';
    serviceConfig = {
      Restart = "always";
      RestartSec = "5s";
      User = "doorserver";
      Group = "doorserver";
      DynamicUser = true;
      LoadCredential = "DOORSERVER_WSSECRET:/var/lib/doorserver/wssecret";
    };
  };
}
