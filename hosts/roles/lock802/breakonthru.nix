 { pkgs, ... }:

let
  breakonthru = pkgs.python311Packages.buildPythonPackage rec {

    pname = "breakonthru";
    version = "0.0";
    pyproject = true;

    src = pkgs.fetchFromGitHub {
      owner = "mcdonc";
      repo = "breakonthru";
      rev = "b761ab0656b3be4158d6ce295227167b1b8ca57c";
      sha256 = "sha256-t0vrQYjSgHcSlLm2NVTOJLBZT6/ZcL6mqeaAkOWEWEA=";
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
      #rpi-gpio
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
        #rpi-gpio
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
  package = breakonthru;
  pyenv = pyenv;
  pyenv-bin = pyenv-bin;
}
