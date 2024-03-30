{ pkgs, ... }:

# Workaround for failure of
#
#   powerManagement.cpuFreqGovernor = lib.mkForce "performance";
#
# check via
#
#   cat /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor
let
  force-perf = pkgs.writeShellScriptBin "force-perf-governor" ''
    echo -n performance | tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor
  '';
in
{
  systemd.services.force-perf-governor = {
    enable = true;
    description = "Work around for failure of powerManagement.cpuFreqGovernor";
    wantedBy = [ "multi-user.target" ];
    serviceConfig= {
      ExecStart = "${force-perf}/bin/force-perf-governor";
      Type = "oneshot";
      RemainAfterExit = true;
    };
  };

}
