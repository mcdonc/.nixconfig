 { pkgs, inputs, pkgs-gpio, ... }:

let
  breakonthru = pkgs-gpio.python312Packages.buildPythonPackage rec {

    pname = "breakonthru";
    version = "0.0";
    pyproject = true;

    src = pkgs-gpio.fetchFromGitHub {
      owner = "mcdonc";
      repo = "breakonthru";
      rev = "3a3d9465ae622a1a6d595f07943d20d8600b2478";
      sha256 = "sha256-RfX6erZIPDmCFgBRPgApU4718/zWyRpZ0ED1/3vQa4k=";
    };

    build-system = with pkgs-gpio.python312Packages; [
      setuptools
    ];

    dependencies = with pkgs-gpio.python312Packages; [
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
    pkgs-gpio.python312.withPackages (p:
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
        #rpi-gpio
        # lgpio etc needs pkgs-gpio instead of pkgs
        lgpio
        pigpio
        rgpio
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
    exec ${pyenv}/bin/doorclient /run/doorclient/client.ini
  '';

in
{
  package = breakonthru;
  pyenv = pyenv;
  pyenv-bin = pyenv-bin;
  doorclient-test = doorclient-test;
}
