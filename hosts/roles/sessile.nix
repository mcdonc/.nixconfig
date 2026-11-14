{ ... }:

{
  # for machines that never move
  services.logind = {
    lidSwitch = "suspend";
    lidSwitchDocked = "ignore";
    lidSwitchExternalPower = "ignore";
    # XXX26.11 extraConfig removed; new settings.Login form
    settings.Login = {
      HandlePowerKey = "suspend";
      IdleAction = "ignore";
    };
  };
  # recommended for audio work
  powerManagement.cpuFreqGovernor = "performance";
}
