{ pkgs, lib, config, ... }:

{
  options.services.idracfanctl = {
    enable = lib.mkOption {
      type = lib.types.bool;
      description = "Enable the idracfanctl service";
      default = true;
    };
    ipmitool = lib.mkOption {
      type = lib.types.package;
      default = pkgs.ipmitool;
      defaultText = lib.literalExpression "pkgs.ipmitool";
      description = "The ipmitool package to use";
    };
    temp-cpu-min = lib.mkOption {
      type = lib.types.int;
      default = 45;
      description = ''
        Script won't adjust fans from fan-percent-min til temp-cpu-min
        in °C is reached.
      '';
    };
    temp-cpu-max = lib.mkOption {
      type = lib.types.int;
      default = 96;
      description = ''
        Max CPU temp in °C that should be allowed before revert to Dell
        dynamic fan control."
      '';
    };
    temp-exhaust-max = lib.mkOption {
      type = lib.types.int;
      default = 65;
      description = ''
        When exhaust temp reaches this value in °C, revert to Dell
        dynamic fan control.
      '';
    };
    fan-percent-min = lib.mkOption {
      type = lib.types.int;
      default = 13;
      description = ''
        The minimum percentage that the fans should run at when under
        script control.
      '';
    };
    fan-percent-max = lib.mkOption {
      type = lib.types.int;
      default = 63;
      description = ''
        The maxmum percentage that the fans should run at when under
        script control.
      '';
    };
    fan-step = lib.mkOption {
      type = lib.types.int;
      default = 2;
      description = ''
        The number of percentage points to step the fan curve by.
      '';
    };
    hysteresis = lib.mkOption {
      type = lib.types.int;
      default = 2;
      description = ''
        Don't change fan speed unless the temp difference in °C exceeds
        this number of degrees since the last fan speed change.
      '';
    };
    sleep = lib.mkOption {
      type = lib.types.int;
      default = 10;
      description = ''
        The number of seconds between attempts to readjust the fan speed
        the script will wait within the main loop.
      '';
    };
    disable-pcie-cooling-response = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        If false, use the default Dell PCIe cooling response, otherwise
        rely on this script to do the cooling even for PCIe cards that
        may not have fans.  NB: changes IPMI settings.
      '';
    };

  };
  config =
    let
      cfg = config.services.idracfanctl;
      idracfanctl = pkgs.stdenv.mkDerivation {
        name = "idracfanctl";
        src = pkgs.fetchFromGitHub {
          owner = "mcdonc";
          repo = "idracfanctl";
          rev = "f7393a7cfcd4b72d48567e4088f179f51790e9aa";
          sha256 = "sha256-pIp9sODUO78D3u8+c/JUA0BWH4V8M7Ohf+DvLE7X5vA=";
        };
        buildInputs = [
          pkgs.makeWrapper
        ];
        installPhase = ''
          mkdir -p $out/bin
          cp idracfanctl.py $out/bin/idracfanctl.py
          makeWrapper ${pkgs.python3.interpreter} $out/bin/idracfanctl \
            --add-flags "$out/bin/idracfanctl.py"
        '';
        meta = with lib; {
          description = "Dell PowerEdge R730xd fan control";
          homepage = "https://github.com/mcdonc/idracfanctl";
          license = licenses.mit;
          platforms = platforms.all;

        };
      };
      execstart = ''${idracfanctl}/bin/idracfanctl \
  --disable-pcie-cooling-response=${if cfg.disable-pcie-cooling-response then "1" else "0"} \
  --ipmitool="${cfg.ipmitool}/bin/ipmitool" \
  --temp-cpu-min=${toString cfg.temp-cpu-min} \
  --temp-cpu-max=${toString cfg.temp-cpu-max} \
  --temp-exhaust-max=${toString cfg.temp-exhaust-max} \
  --fan-percent-min=${toString cfg.fan-percent-min} \
  --fan-percent-max=${toString cfg.fan-percent-max} \
  --fan-step=${toString cfg.fan-step} \
  --hysteresis=${toString cfg.hysteresis} \
  --sleep=${toString cfg.sleep}'';
    in
    lib.mkIf cfg.enable {
      systemd.services.idracfanctl = {
        description = "Control Dell R730xd fans";
        after = [ "local-fs.target" ];
        before = [ "multi-user.target" ];
        wantedBy = [ "multi-user.target" ];

        serviceConfig = {
          ExecStart = "${execstart}";
          Restart = "always";
          User = "root";
          KillSignal = "SIGINT";
        };
      };
    };
}
