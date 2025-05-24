{ pkgs, ... }:
{
  # desktop stuff
  services.xserver.enable = true;
  services.displayManager.sddm.enable = true;
  services.displayManager.defaultSession = "plasmax11";
  services.desktopManager.plasma6.enable = true;
  services.xserver.displayManager.sessionCommands =
    let modmap = pkgs.writeText "modmap" ''
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
    in "${pkgs.xorg.xmodmap}/bin/xmodmap ${modmap}";

  services.xserver.xkb.layout = "us";
  services.xserver.xkb.options = "ctrl:nocaps,terminate:ctrl_alt_bksp";
  services.xserver.enableCtrlAltBackspace = true;
  services.xserver.dpi = 96;
  services.libinput.enable = true; # touchpad
  fonts.packages = [
    pkgs.nerd-fonts.ubuntu-mono
  ];
}
