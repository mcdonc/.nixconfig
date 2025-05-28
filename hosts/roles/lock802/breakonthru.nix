 { pkgs, inputs, pkgs-gpio, ... }:

let
  breakonthru = pkgs.python312Packages.buildPythonPackage rec {

    pname = "breakonthru";
    version = "0.0";
    pyproject = true;

    src = pkgs.fetchFromGitHub {
      owner = "mcdonc";
      repo = "breakonthru";
      rev = "1dcbda5bc2f339ab5b609f8dc3eb30eee920ea97";
      sha256 = "sha256-fiFfUg7pWq3vYyuA/3klwh/Hq+n0eGraM8RBuFNSMqQ=";
    };

    build-system = with pkgs.python312Packages; [
      setuptools
    ];

    dependencies = with pkgs.python312Packages; [
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

  # RPi.GPIO issue https://github.com/home-assistant/operating-system/issues/3094
  # https://github.com/joan2937/pigpio
  # https://github.com/NixOS/nixpkgs/pull/352308 (doronbehar)
  # why must i repeat this?
  pyenv = (
    pkgs.python312.withPackages (p:
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
        pexpect
        setproctitle
        requests
        websocket-client
        gpiozero
        rpi-gpio
        # lgpio etc needs pkgs-gpio instead of pkgs
        #lgpio
        #pigpio
        #rgpio
      ]
    )
  );

  # using rpi.gpio because
  # lgpio currently doesnt work: /nix/store/2gpij2mn31z0hnfy0803m9w34jzyjbhk-python3-3.12.10-env/lib/python3.12/site-packages/gpiozero/devices.py:300: PinFactoryFallback: Falling back from lgpio: 'can not open gpiochip'

  pyenv-bin = pkgs.writeShellScriptBin "pyenv-bin" ''
    exec ${pyenv}/bin/python $@
  '';

  doorclient-test = pkgs.writeShellScriptBin "doorclient-test" ''
    export PYTHONPATH=/home/chrism/breakonthru
    exec ${pyenv}/bin/doorclient "$@"
  '';

in
{
  package = breakonthru;
  pyenv = pyenv;
  pyenv-bin = pyenv-bin;
  doorclient-test = doorclient-test;
}
