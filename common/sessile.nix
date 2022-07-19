{lib, ...}:

{
  # for machines that never move
  services.logind = {
    lidSwitch = "suspend";
    lidSwitchDocked = "ignore";
    lidSwitchExternalPower = "ignore";
    extraConfig = ''
      HandlePowerKey=suspend
      IdleAction=ignore
    '';
  };
}
