{ pkgs, ... }:

{
  systemd.services.nix-index = {
    serviceConfig.Type = "oneshot";
    script = "${pkgs.nix-index}/bin/nix-index";
  };

  systemd.timers.nix-index = {
    wantedBy = [ "timers.target" ];
    partOf = [ "nix-index.service" ];
    timerConfig = {
      # 4 am
      OnCalendar = "*-*-* 04:00:00";
      Unit = "nix-index.service";
    };
  };
}
