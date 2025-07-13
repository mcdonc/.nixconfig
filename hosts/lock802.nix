{
  pkgs,
  lib,
  inputs,
  config,
  pkgs-unstable,
  ...
}:

let
  breakonthru = (import ./roles/lock802/breakonthru.nix) {
    inherit
      pkgs
      lib
      inputs
      pkgs-unstable
      ;
  };

  playwav = pkgs.writeShellScriptBin "playwav" ''
    ${breakonthru.pyenv}/bin/wavplayer --dir=/var/lib/doorserver/wavs/$1
  '';
in

{
  imports = [
    inputs.nixos-generators.nixosModules.all-formats
    ../users/chrism
    ./roles/minimal.nix
    ./roles/rpi4.nix
    ./roles/dnsovertls/resolvedonly.nix
    ./roles/lock802/doorclient.nix
    ./roles/mailrelayer.nix
    ./roles/journalwatch.nix
  ];

  # system.autoUpgrade = {
  #   enable = true;
  #   flake = "github:mcdonc/.nixconfig#lock802";
  #   dates = "04:54";
  #   allowReboot = true;
  #   flags = [
  #     "--no-write-lock-file"
  #     # for individual:
  #     "--update-input" "nixpkgs"
  #     # "--recreate-lock-file" # for all inputs
  #   ];
  # };

  security.sudo.wheelNeedsPassword = false;

  boot.initrd.availableKernelModules = [
    "xhci_pci"
    "usbhid"
  ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ ];
  boot.extraModulePackages = [ ];

  system.stateVersion = "25.05";

  networking.hostId = "c923c531";
  networking.hostName = "lock802";

  boot.kernel.sysctl."net.ipv6.conf.all.disable_ipv6" = true;
  networking.enableIPv6 = false;
  # none of the above works, use "ipv6.disable=1"
  # alternately
  # nmcli d modify wlan0 ipv6.method "disabled"
  boot.kernelParams = [
    "ipv6.disable=1"
    "iomem=relaxed" # for pigpiod
    #"strict-devmem=0" # for pigpiod (doesnt seem necessary)
  ];

  # networkmanager try connect
  # sudo nmcli device wifi connect "ssid"
  # or
  # sudo nmcli device wifi connect "ssid" --ask
  # or
  # sudo nmcli device wifi connect "ssid" password "password"

  age.secrets."pjsua.conf" = {
    file = ../secrets/pjsua.conf.age;
    mode = "644";
  };
  age.secrets."pjsip.conf" = {
    file = ../secrets/pjsip.conf.age;
    mode = "644";
  };
  age.secrets."wssecret" = {
    file = ../secrets/wssecret.age;
    mode = "644";
  };
  age.secrets."wifi" = {
    file = ../secrets/wifi.age;
    mode = "600";
  };

  networking = {
    firewall.enable = lib.mkForce false;
    interfaces.end0.useDHCP = true;
    interfaces.wlan0.useDHCP = true;
    wireless = {
      secretsFile = config.age.secrets."wifi".path;
      enable = true;
      interfaces = [ "wlan0" ];
      networks."haircut".pskRaw = "ext:psk";
    };
    networkmanager.enable = lib.mkForce false;
  };
  # "wpa_passphrase ssid passphrase" creates a psk
  # "iwconfig" shows connected ssids

  services.dnsmasq.enable = true;
  services.dnsmasq.settings.listen-address = "127.0.0.1";
  services.dnsmasq.settings.bind-interfaces = true; # dont wildcard bind

  services.doorclient.enable = true;
  services.doorclient.pjsua-conf = config.age.secrets."pjsua.conf".path;
  services.doorclient.wssecret-file = config.age.secrets."wssecret".path;
  services.doorclient.callbutton-bouncetime = 2; # milliseconds
  #services.doorclient.nopage = true;

  systemd.services.pigpiod = {
    after = [ "network.target" ]; # XXX
    wantedBy = [ "multi-user.target" ]; # XXX
    description = "";
    script = "${pkgs-unstable.pigpio}/bin/pigpiod -g -l";
    serviceConfig = {
      Restart = "always";
      RestartSec = "5s";
    };
  };

  users.users.chrism.extraGroups = [
    "gpio"
    "kmem"
  ];

  services.pulseaudio.enable = false; # completely alsa setup

  # run "aplay -l" to see alsa interface numbers

  # the settings in asound.conf are 100% brequired. even though pjsua.conf
  # appears to allow us to choose capture and playback devices, it appears to
  # always use the default device.  when the default device is not correct
  # (e.g. the headphone device, it'll look something like pjsua_aud.c .Unable
  # to open sound device: Unknown error from audio driver (PJMEDIA_EAUD_SYSERR)
  # [status=420002] commenting out the --capture-device in pjsua.conf makes it
  # work, stupidly, but then it doesn't capture.  this presumably is because
  # it's defaulting to card 0, the headphone card, which doesn't have a capture
  # component.  the only reliable way to make it work is to set up asound.conf
  # with defaults to the right card AFAICT.  EDIT: yeah, the --capture-device
  # and --playback-device in pjsua.conf aren't the ALSA card numbers.  0 means
  # "default ALSA device".

  # NB: hardware.alsa.config doesn't work to set these values
  environment.etc."asound.conf".text = ''
    defaults.pcm.card 1
    defaults.ctl.card 1
  '';

  environment.systemPackages = [
    pkgs.usbutils # lsusb
    pkgs.pciutils # lspci
    pkgs.wirelesstools # iwconfig
    pkgs.wpa_supplicant # wpa_passphrase
    pkgs-unstable.pigpio # pigpiod
    playwav
  ];

  services.asterisk.enable = true;
  services.asterisk.confFiles = {
    "extensions.conf" = ''
      [internal]
      ; page
      exten => 7000,1,Answer()
      exten => 7000,2,Dial(PJSIP/7002& PJSIP/7003& PJSIP/7004& PJSIP/7005& PJSIP/7006,30)
      exten => 7000,3,Hangup()

      ; front door
      exten => 7001,1,Answer()
      exten => 7001,2,Dial(PJSIP/7001,30)
      exten => 7001,3,Hangup()

      ; me
      exten => 7002,1,Answer()
      exten => 7002,2,Dial(PJSIP/7002,30)
      exten => 7002,3,Hangup()

      exten => 7003,1,Answer()
      exten => 7003,2,Dial(PJSIP/7003,30)
      exten => 7003,3,Hangup()

      exten => 7004,1,Answer()
      exten => 7004,2,Dial(PJSIP/7004,30)
      exten => 7004,3,Hangup()

      exten => 7005,1,Answer()
      exten => 7005,2,Dial(PJSIP/7005,30)
      exten => 7005,3,Hangup()

      ; larry
      exten => 7006,1,Answer()
      exten => 7006,2,Dial(PJSIP/7006,30)
      exten => 7006,3,Hangup()

      ; melinda
      exten => 7007,1,Answer()
      exten => 7007,2,Dial(PJSIP/7007,30)
      exten => 7007,3,Hangup()

      exten => 7008,1,Answer()
      exten => 7008,2,Dial(PJSIP/7008,30)
      exten => 7008,3,Hangup()
    '';
  };

  # XXX reads into nix store
  environment.etc."asterisk/pjsip.conf".source =
    lib.mkForce
      config.age.secrets."pjsip.conf".path;

  ##############################################################################
  #                      upside down text: "raspberry pi 4B"
  #
  #o   o   o   o   o   o   o   o   o   o   o   o   o   o   o   o   o   o   o   o
  #G  26      13               G                               G             3.3
  #   FD
  #  BRN                                                                     ORG
  #
  #o   o   o   o   o   o   o   o   o   o   o   o   o   o   o   o   o   o   o   o
  #       16   G                           G  24                       G      5V  #       CB                                  ID
  #       WH  BLU                            GRN                     BLK     RED
  #
  # relay sitting on bottom of box is for front door unlock: brown to 26
  # relay stuck to door on left is inner door unlock: green to 24
  # relay stuck to door on right is for callbutton
  ##############################################################################

  systemd.services.playwav-late = {
    description = "Play late night wavs";
    script = "${playwav}/bin/playwav late";
    serviceConfig = {
      Type = "oneshot";
      User = "chrism";
    };
  };

  systemd.timers.playwav-late = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "23:01";
      Persistent = true;
    };
  };

  systemd.services.playwav-early = {
    description = "Play early morning wavs";
    script = "${playwav}/bin/playwav early";
    serviceConfig = {
      Type = "oneshot";
      User = "chrism";
    };
  };

  systemd.timers.playwav-early = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "08:02";
      Persistent = true;
    };
  };

  systemd.services.playwav-afternoon = {
    description = "Play afternoon wavs";
    script = "${playwav}/bin/playwav afternoon";
    serviceConfig = {
      Type = "oneshot";
      User = "chrism";
    };
  };

  systemd.timers.playwav-afternoon = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "15:06";
      Persistent = true;
    };
  };

  systemd.services.playwav-evening = {
    description = "Play evening wavs";
    script = "${playwav}/bin/playwav evening";
    serviceConfig = {
      Type = "oneshot";
      User = "chrism";
    };
  };

  systemd.timers.playwav-evening = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "18:32";
      Persistent = true;
    };
  };

}
