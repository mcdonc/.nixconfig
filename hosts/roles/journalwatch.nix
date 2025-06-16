{ ... }:
let
  ALL = ".*";
in
{
  services.journalwatch.enable = true;
  services.journalwatch.mailTo = "chrism@repoze.org";
  services.journalwatch.priority = 5;
  services.journalwatch.interval = "0/3:00";
  #services.journalwatch.interval = "daily";
  services.journalwatch.accuracy = "5min";
  services.journalwatch.filterBlocks = [
    {
      match = "SYSLOG_IDENTIFIER = systemd";
      filters = ''
        (Stopped|Stopping|Starting|Started) .*
        (Created slice|Removed slice) user-\d*\.slice\.
        Received SIGRTMIN\+24 from PID .*
        (Reached target|Stopped target) .*
        Startup finished in \d*ms\.
        Reexecution requested .*
        Reexecuting\.
        Reexecuted\.
        Reload requested .*
        syncoid-home.*
        nix-index.*
        pulseaudio.*
        nixos-rebuild-switch-to-configuration.service.*
        /etc/systemd/system/cups.socket.*
        vte-spawn.*
        [A-Za-z0-9_@\.]+.service Consumed .*
      '';
    }
    {
      # relies on fail2ban to do our auditing of this stuff
      match = "SYSLOG_IDENTIFIER = sshd-session";
      filters = ''
        error: PAM: Authentication failure for .*
      '';
    }
    {
      # nixos-rebuild
      match = "_SYSTEMD_UNIT = postfix.service";
      filters = ''
        warning: .*
      '';
    }
    {
      match = "SYSLOG_IDENTIFIER = redis";
      filters = ALL;
    }
    {
      match = "SYSLOG_IDENTIFIER = zed";
      filters = ALL;
    }
    {
      match = "SYSLOG_IDENTIFIER = polkitd";
      filters = ALL;
    }
    {
      # nixos-rebuild
      match = "SYSLOG_IDENTIFIER = /(.os-prober-wrapped|50mounted-tests)/";
      filters = ALL;
    }
    {
      # nixos-rebuild
      match = "SYSLOG_IDENTIFIER = /(p4|p5)/";
      filters = ALL;
    }
    {
      match = "SYSLOG_IDENTIFIER = plasmashell";
      filters = ALL;
    }
    {
      match = "SYSLOG_IDENTIFIER = rspamd";
      filters = ALL;
    }
    {
      match = "SYSLOG_IDENTIFIER = dhcpd";
      filters = ALL;
    }
    {
      # nixos-rebuild
      match = "_SYSTEMD_UNIT = libvirtd.service";
      filters = ALL;
    }
    {
      # not useful
      match = "_SYSTEMD_UNIT = dbus.service";
      filters = ALL;
    }
    {
      # user services
      match = "_SYSTEMD_UNIT = /user@\d+\.service/";
      filters = ALL;
    }
    {
      # not useful
      match = "_SYSTEMD_UNIT = ModemManager.service";
      filters = ALL;
    }
  ];
}
