  # # systemctl --user status nix-index.service
  # systemd.user.services.nix-index = {
  #   Unit = {
  #     Description = "Run nix-index.";
  #   };
  #   Service = {
  #     Type = "oneshot";
  #     ExecStart = "${pkgs.nix-index}/bin/nix-index";
  #   };
  #   Install = {
  #     WantedBy = [ "default.target" ];
  #   };
  # };

  # # systemctl --user status nix-index.timer
  # systemd.user.timers.nix-index = {
  #   Unit = {
  #     Description = "Timer for nix-index.";
  #   };
  #   Timer = {
  #     Unit = "nix-index.service";
  #     #OnCalendar = "*:0/5";
  #     OnCalendar = "*-*-* 10:00:00";
  #   };
  #   Install = {
  #     WantedBy = [ "timers.target" ];
  #   };
  # };

  # systemd.user.services.watchintake = {
  #   Unit = {
  #     Description = "Run watchintake.";
  #   };
  #   Service = {
  #     ExecStart = ''
  #       ${watchintake}/bin/watchintake ${homedir}/intake
  #     '';
  #   };
  #   Install = {
  #     WantedBy = [ "default.target" ];
  #   };
  # };

