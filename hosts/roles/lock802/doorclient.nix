{ pkgs, lib, config, inputs, ... }:

let
  breakonthru = (import ./breakonthru.nix) {
    inherit pkgs lib inputs;
  };
  pjsip = (pkgs.pjsip.overrideAttrs (oldAttrs: {
      patches = (oldAttrs.patches or []) ++ [ ./pjsip-alsa.patch ];
    }));
in {
  options.services.doorclient = {
    enable = lib.mkOption {
      type = lib.types.bool;
      description = "Enable the doorlient service";
      default = false;
    };
    websocket-url = lib.mkOption {
      type = lib.types.str;
      description = "Server URL";
      default = "wss://lock802ws.repoze.org/";
    };
    wssecret-file = lib.mkOption {
      type = lib.types.str;
      description = "Path to the wssecret file";
      default = "/var/lib/doorserver/wssecret";
    };
    unlock0-gpio-pin = lib.mkOption {
      type = lib.types.int;
      description = "Unlock pin for door 0";
      default = 26;
    };
    unlock1-gpio-pin = lib.mkOption {
      type = lib.types.int;
      description = "Unlock pin for door 1";
      default = 24;
    };
    unlock2-gpio-pin = lib.mkOption {
      type = lib.types.int;
      description = "Unlock pin for door 2";
      default = 13;
    };
    door-unlocked-duration = lib.mkOption {
      type = lib.types.int;
      description = "Unlock duration in seconds";
      default = 5;
    };
    clientidentity = lib.mkOption {
      type = lib.types.str;
      description = "client identity string";
      default = "doorclient";
    };
    paging-sip = lib.mkOption {
      type = lib.types.str;
      description = "Door SIP";
      default = "sip:7002@127.0.0.1:5065";
    };
    page-throttle-duration = lib.mkOption {
      type = lib.types.int;
      description = "Paging throttle duration";
      default = 15;
    };
    callbutton-gpio-pin = lib.mkOption {
      type = lib.types.int;
      description = "GPIO pin for call button";
      default = 16;
    };
    callbutton-bouncetime = lib.mkOption {
      type = lib.types.int;
      description = "Bounce time in millseconds for callbutton";
      default = 1;
    };
    pjsua-conf = lib.mkOption {
      type = lib.types.str;
      description = "Path to pjsua.conf";
      default = "/etc/pjsua.conf";
    };
    nopage = lib.mkOption {
      type = lib.types.bool;
      description = "Disable doorclient paging components";
      default = false;
    };
    pin-factory = lib.mkOption {
      type = lib.types.str;
      description = "for gpiozero: one of lgpio|rpigpio|pgpio|native|mock";
      default = "lgpio";
    };

  };


  config = let
    cfg = config.services.doorclient;
    client_ini = ''
      [doorclient]
      server = ${cfg.websocket-url}
      unlock0_gpio_pin = ${toString cfg.unlock0-gpio-pin}
      unlock1_gpio_pin = ${toString cfg.unlock1-gpio-pin}
      unlock2_gpio_pin = ${toString cfg.unlock2-gpio-pin}
      door_unlocked_duration = ${toString cfg.door-unlocked-duration}
      callbutton_gpio_pin = ${toString cfg.callbutton-gpio-pin}
      callbutton_bouncetime = ${toString cfg.callbutton-bouncetime}
      clientidentity = ${cfg.clientidentity}
      pjsua_bin = ${pjsip}/bin/pjsua
      pjsua_config_file = ${cfg.pjsua-conf}
      paging_sip = ${cfg.paging-sip}
      page_throttle_duration = ${toString cfg.page-throttle-duration}
    '';
    creds = [
      "DOORSERVER_WSSECRET_FILE:${cfg.wssecret-file}"
    ];

    envs = [
      "DOORSERVER_WSSECRET_FILE=:%d/DOORSERVER_WSSECRET_FILE"
    ];

  in

    lib.mkIf cfg.enable {
      environment.systemPackages = [
        breakonthru.pyenv-bin
        breakonthru.doorclient-test
        pjsip
      ];
      systemd.services.doorclient = {
        description = "Door client";
        after = [ "network.target" ];
        wantedBy = [ "multi-user.target" ];
        preStart = ''
mkdir -p /run/doorclient
cat > /run/doorclient/client.ini << EOF
${client_ini}
EOF
chown -R doorserver:doorserver /run/doorclient
        '';
        script = ''
          secret=$(cat $CREDENTIALS_DIRECTORY/DOORSERVER_WSSECRET_FILE)
          export DOORSERVER_WSSECRET="$secret"
          ${if cfg.nopage then "export DOORSERVER_NOPAGE=1" else ""}
          export GPIOZERO_PIN_FACTORY=${cfg.pin-factory}
          echo "using pin factory $GPIOZERO_PIN_FACTORY"
          exec ${breakonthru.pyenv}/bin/doorclient /run/doorclient/client.ini
        '';
        serviceConfig = {
          Restart = "always";
          RestartSec = "5s";
          User = "doorserver";
          Group = "doorserver";
          DynamicUser = true;
          PermissionsStartOnly = true; # run preStart as root
          LoadCredential = creds;
          Environment = envs;
          WorkingDirectory = "/tmp"; # for lgpio
          SupplementaryGroups = [ "audio" "kmem" "gpio" ]; # kmem for lgpio
        };
      };

    };
}
