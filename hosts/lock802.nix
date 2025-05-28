{ pkgs, lib, inputs, pkgs-gpio, ... }:

let
  breakonthru = (
    import ./roles/lock802/breakonthru.nix
    ) {inherit pkgs lib inputs pkgs-gpio;};

  playwav = pkgs.writeShellScriptBin "playwav" ''
    ${breakonthru.pyenv}/bin/wavplayer --dir=/var/lib/doorserver/wavs/$1
  '';

in
{
  imports = [
    inputs.nixos-generators.nixosModules.all-formats
    "${inputs.nixos-hardware}/raspberry-pi/4"
    ../users/chrism
    ./roles/minimal
    ./roles/rpi4.nix
    ./roles/lock802/doorclient.nix
  ];

  boot.initrd.availableKernelModules = [ "xhci_pci" "usbhid" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ ];
  boot.extraModulePackages = [ ];

  system.stateVersion = "25.05";

  networking.hostId = "c923c531";
  networking.hostName = "lock802";
  boot.kernel.sysctl."net.ipv6.conf.wlan0.disable_ipv6" = true;
  boot.kernel.sysctl."net.ipv6.conf.end0.disable_ipv6" = true;
  # none of the above works, use
  # nmcli d modify wlan0 ipv6.method "disabled"

  networking.enableIPv6 = false;
  networking.firewall.enable = lib.mkForce false;
  networking.networkmanager.enable = lib.mkForce true;

  # networkmanager try connect
  # sudo nmcli device wifi connect "ssid"
  # or
  # sudo nmcli device wifi connect "ssid" --ask
  # or
  # sudo nmcli device wifi connect "ssid" password "password"

  # to use wpa_supplicant, disable networkmanager and add this (routing
  # doesnt work on wifi via networking.foo settings)

  #networking.wireless.enable = true;
  #networking.wireless.secretsFile = "/var/lib/secrets/wifi";
  #networking.wireless.networks.haircut.pskRaw = "ext:psk";
  #networking.wireless.networks.ytvid-rpi.pskRaw = "18a90748cff3ae6006b78dc2b4a65be47f7e8eb22c46388b636314b535486dcb";

  # "wpa_passphrase ssid passphrase" creates a psk
  # "iwconfig" shows connected ssids

  #networking = {
  #  interfaces.end0 = {
  #    ipv4.addresses = [{
  #      address = "192.168.1.185";
  #      prefixLength = 24;
  #    }];
  #  };
  #  defaultGateway = {
  #    address = "192.168.1.1";
  #    interface = "end0";
  #  };
  #  nameservers = [
  #    "192.168.1.1"
  #  ];
  #};

  # end wpa_supplicant

  services.doorclient.enable = true;
  users.users.chrism.extraGroups = [ "gpio" "kmem" ];

  services.pulseaudio.enable = true;

  # run "sudo pacmd list-sources" to see alsa interface numbers

  # goes into /etc/asound.conf
  hardware.alsa.config = ''
    defaults.pcm.card 1
    defaults.ctl.card 1
  '';

  environment.systemPackages = [
    pkgs.usbutils # lsusb
    pkgs.pciutils # lspci
    pkgs.wirelesstools # iwconfig
    pkgs.wpa_supplicant # in case i decide to use it
    playwav
  ];

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

  # crontab -e of pi user
  # 23 1 * * *      /home/pi/lock802/playwav.sh late
  # 8 2 * * *       /home/pi/lock802/playwav.sh early
  # 15 6 * * *      /home/pi/lock802/playwav.sh afternoon
  # 18 32 * * *     /home/pi/lock802/playwav.sh evening
  # #*/10 * * * *   /home/pi/lock802/playwav.sh tenmins

}
