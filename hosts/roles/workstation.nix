{
  config,
  pkgs,
  lib,
  ...
}:

{
  jawns.isworkstation = true;

  # cachix auth token for swnix/nhswnix aliases
  age.secrets."mcdonc-unhappy-cachix-authtoken" = {
    file = ../../secrets/mcdonc-unhappy-cachix-authtoken.age;
    mode = "640";
    owner = "chrism";
    group = "users";
  };

  imports = [
    ./shared.nix
    ./packages.nix
  ];

  # obs
  boot.extraModulePackages = with config.boot.kernelPackages; [ v4l2loopback ];

  # rtl8153 / tp-link ue330 quirk for USB ethernet, see
  # https://askubuntu.com/questions/1081128/usb-3-0-ethernet-adapter-not-working-ubuntu-18-04
  # disables link power management for this usb ethernet adapter; won't work
  # otherwise
  boot.kernelParams = [
    "usbcore.quirks=2357:0601:k,0bda:5411:k" # ethernet, hub
  ];

  networking.networkmanager.enable = true;
  networking.firewall.enable = false;

  time.timeZone = "America/New_York";

  hardware.bluetooth.enable = true;
  hardware.enableAllFirmware = true;

  hardware.flipperzero.enable = true;

  # virtualization
  virtualisation.libvirtd.enable = true;
  #virtualisation.virtualbox.host = {
  #  enable = true;
  #  enableExtensionPack = true;
  #};

  # vmVariant configuration is added only when building VM with nixos-rebuild
  # build-vm
  virtualisation.vmVariant = {
    virtualisation = {
      memorySize = 8192; # Use 8GB memory (value is in MB)
      cores = 4;
    };
  };

  virtualisation.docker = {
    enable = true;
    daemon.settings = {
      # This is equivalent to enabling "features.buildkit: true" in daemon.json
      "features" = {
        "buildkit" = true;
      };
    };
  };

  programs.dconf.enable = true;

  services.locate.enable = false;

  # wireshark without sudo; note that still necessary to add
  # wireshark to systemPackages to get gui I think
  programs.wireshark.enable = true;

  #programs.direnv.enable = true;
  #programs.direnv.enableZshIntegration = true;

  # # this causes weirdness when vim is exited, printing mouse movements
  # # as ANSI sequences on any terminal; use shift to select text as a
  # # workaround
  # environment.etc."vimrc".text = ''
  #   " get rid of maddening mouseclick-moves-cursor behavior
  #   set mouse=
  #   set ttymouse=
  # '';

  # run appimages directly (see https://nixos.wiki/wiki/Appimage)
  boot.binfmt = {
    registrations.appimage = {
      wrapInterpreterInShell = false;
      interpreter = "${pkgs.appimage-run}/bin/appimage-run";
      recognitionType = "magic";
      offset = 0;
      mask = "\\xff\\xff\\xff\\xff\\x00\\x00\\x00\\x00\\xff\\xff\\xff";
      magicOrExtension = "\\x7fELF....AI\\x02";
    };
    # run aarch64 binaries
    emulatedSystems = [ "aarch64-linux" ];
  };

  # desktop stuff
  services.xserver.enable = true;
  services.displayManager.sddm.enable = true;
  services.displayManager.defaultSession = "plasmax11"; # "plasma";
  services.desktopManager.plasma6.enable = true;
  services.xserver.displayManager.sessionCommands =
    let
      modmap = pkgs.writeText "modmap" ''
        ! disable middle click
        ! pointer = 1 0 3 4 5
        ! map right-ctrl+arrow-keys to pgup/pgdn/home/end
        ! see https://forums.linuxmint.com/viewtopic.php?t=321400
        ! keycode <number> = <default> <shift> <alt> <alt+shift>
        ! keycode 105 is right-ctrl
        keycode 105 = Mode_switch
        keycode 113 = Left NoSymbol Home
        keycode 114 = Right NoSymbol End
        keycode 111 = Up NoSymbol Prior
        keycode 116 = Down NoSymbol Next
        ! map alt-pgup to home and alt-pgdn to end
        ! keycode 108 is right-alt
        keycode 108 = Mode_switch
        keycode 112 = Prior NoSymbol Home
        keycode 117 = Next NoSymbol End
      '';
    in
    "${pkgs.xorg.xmodmap}/bin/xmodmap ${modmap}";

  services.xserver.xkb.layout = "us";
  services.xserver.xkb.options = "ctrl:nocaps,terminate:ctrl_alt_bksp";
  services.xserver.enableCtrlAltBackspace = true;
  services.xserver.dpi = 96;
  services.libinput.enable = true; # touchpad
  fonts.packages = [
    pkgs.nerd-fonts.ubuntu-mono
  ];

  # match "Jun 19 13:00:01 thinknix512 cupsd[2350]: Expiring subscriptions..."
  systemd.services.cups = {
    overrideStrategy = "asDropin";
    serviceConfig.LogFilterPatterns = "~.*Expiring subscriptions.*";
  };

  services.printing.enable = true;
  #https://discourse.nixos.org/t/newly-announced-vulnerabilities-in-cups/52771/9
  systemd.services.cups-browsed.enable = false;

  services.pulseaudio.enable = false;
  services.pipewire = {
    enable = true;
    alsa = {
      enable = true;
      support32Bit = true;
    };
    jack.enable = true;
    pulse.enable = true;
  };

  services.mullvad-vpn.enable = true;

}
