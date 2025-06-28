{ ... }:
let
  ALL = ".*";
in
{
  services.journalwatch.enable = true;
  services.journalwatch.mailTo = "chrism@repoze.org";
  services.journalwatch.priority = 5;
  #services.journalwatch.interval = "0/2:00"; # every 2 hours (12,2,4,etc)
  services.journalwatch.interval = "05:09"; # every day at 05:09am
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
        kbfs.service.*
        home.mount.*
        boot.mount.*
        nixos-rebuild-switch-to-configuration\.service.*
        /etc/systemd/system/cups\.socket.*
        vte-spawn.*
        [A-Za-z 0-9_@\.\-]+\.(scope|service|slice): Consumed .*
        ollama-model-loader\.service: .*
        tailscale-autoconnect\.service: .*
        plasma-\w+\.service: .*
        app-org\.gnome-\w+\.(service|slice): .*
        xdg-desktop-portal-gtk\.service: .*
        gnome-terminal-service\.service: .*
      '';
    }
    {
      # relies on fail2ban to do our auditing of this stuff
      match = "SYSLOG_IDENTIFIER = sshd-session";
      filters = ''
        error: PAM: Authentication failure for .*
        error: key_exchange_identification: .*
        error: Protocol major versions differ: .*
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
      # arctor noise
      match = "_SYSTEMD_UNIT = sshd.service";
      filters = ''
        error: maximum authentication attempts exceeded .*
        error: kex_exchange_identification: .*
        error: kex_protocol_error: .*
      '';
    }
    {
      # not useful
      match = "_SYSTEMD_UNIT = /(libvirtd\.service|dbus\.service|udisks2\.service|systemd-udevd\.service|user@\d+\.service|do-agent\.service|dhcpcd\.service)/";
      filters = ALL;
    }
    {
      # not useful
      match = "SYSLOG_IDENTIFIER = /(sddm|kglobalacceld|kded6|ksmserver|kwin_x11|gmenudbusmenuproxy|kwalletd6|winbindd|kactivitymanagerd|pipewire|kalendarac|nmbd|samba-dcerpcd|smbd|rpcd_lsad|sddm-helper|drkonqi-coredump-launcher|kscreenlocker_greet|systemd-resolved|kdeconnectd|cupsd|org_kde_powerdevil|ksystemstats|wireplumber|kconf-update|pipewire-pulse|pipewire|avahi-daemon|kconf_update|ModemManager|udevadm|kscreen_backend_launcher|kaccess|kernel|systemd-coredump|pressure-vessel-wrap|steam-runtime-steam-remote|baloorunner|krunner|okular|redis|zed|polkitd|\.os-prober-wrapped|50mounted-tests|plasmashell|rspamd|dhcpd|systemd-gpt-auto-generator|kscreenlocker\.greet|nm-openvpn|plasma-emojier|wpa_supplicant|asterisk)/";
      filters = ALL;
    }
  ];
}
