NixOS 34: Squashing an Irritating "A Stop Job Is Running For..." Shutdown Issue in NixOS 22.05
==============================================================================================

- Companion to video at ...

- See the other videos in this series by visiting the playlist at
  https://www.youtube.com/playlist?list=PLa01scHy0YEmg8trm421aYq4OtPD8u1SN

Video Script
------------

- ``dhcpd`` has problems stopping at system shutdown when this bit of config is
  present ("A stop job is running for DHCP Client...")::

    networking.useDHCP = true;

- The provenance of this particular NixOS option is storied:
  https://github.com/NixOS/nixpkgs/pull/167327/files/8e42949a2421485c34fa56cff3e768af1c91459e
  .  I won't try to know wtf is going on.
  
- Via ``journalctl -b -1`` we can see the issue.  ``dhcpd`` gets a stop request
  at 13:43:39 and only finally stops at 13:45:09.  The delay is because it did
  not respond to a SIGTERM and had to be SIGKILL'ed.::

    Jul 21 13:43:39 thinknix52 dhcpcd[41430]: wlp0s20f3: deleting address 2600:8806:4800:55::66d/128
    Jul 21 13:43:39 thinknix52 dhcpcd[41430]: wlp0s20f3: deleting address fdfd:83ab:b09a::66d/128
    Jul 21 13:43:39 thinknix52 systemd[1]: save-hwclock.service: Deactivated successfully.
    Jul 21 13:43:39 thinknix52 systemd[1]: Finished Save Hardware Clock.
    Jul 21 13:43:39 thinknix52 xserver-wrapper[2920]: (II) event14 - Elan Touchpad: device removed
    Jul 21 13:43:39 thinknix52 xserver-wrapper[2920]: (II) event15 - Elan TrackPoint: device removed
    Jul 21 13:43:39 thinknix52 dhcpcd[41430]: wlp0s20f3: deleting address 2600:8806:4800:55:95bb:c28b:da8d:192b/64
    Jul 21 13:43:39 thinknix52 dhcpcd[41430]: wlp0s20f3: deleting address fdfd:83ab:b09a:0:95bb:c28b:da8d:192b/64
    Jul 21 13:43:39 thinknix52 systemd[1]: tlp.service: Deactivated successfully.
    Jul 21 13:43:39 thinknix52 dhcpcd[41430]: wlp0s20f3: deleting route to fdfd:83ab:b09a::/64
    Jul 21 13:43:39 thinknix52 systemd[1]: Stopped TLP system startup/shutdown.
    Jul 21 13:43:39 thinknix52 dhcpcd[41430]: wlp0s20f3: deleting route to 2600:8806:4800:55::/64
    Jul 21 13:43:39 thinknix52 systemd[1]: Stopped target Multi-User System.
    Jul 21 13:43:39 thinknix52 dhcpcd[41430]: wlp0s20f3: deleting default route via fe80::7ad2:94ff:fea3:9df5
    Jul 21 13:43:39 thinknix52 systemd[1]: Stopped target Login Prompts.
    Jul 21 13:43:39 thinknix52 systemd[1]: Stopped target Containers.
    Jul 21 13:43:39 thinknix52 systemd[1]: Stopped target Network is Online.
    Jul 21 13:43:39 thinknix52 systemd[1]: Stopped target ZFS startup target.
    Jul 21 13:43:39 thinknix52 systemd[1]: Stopped target ZFS pool import target.
    Jul 21 13:43:39 thinknix52 systemd[1]: Stopping Store Sound Card State...
    Jul 21 13:43:39 thinknix52 dhcpcd[41430]: wlp0s20f3: deleting route to 192.168.1.0/24
    Jul 21 13:43:39 thinknix52 wpa_supplicant[2956]: wlp0s20f3: CTRL-EVENT-DISCONNECTED bssid=7a:d2:94:a3:9d:f8 reason=3 locally_generated=1
    Jul 21 13:43:39 thinknix52 systemd[1]: Stopping DHCP Client...
    Jul 21 13:43:39 thinknix52 systemd[1]: Stopping Getty on tty1...
    Jul 21 13:43:39 thinknix52 systemd[1]: Stopping Stop Intel throttling...
    Jul 21 13:43:39 thinknix52 wpa_supplicant[2956]: wlp0s20f3: CTRL-EVENT-DSCP-POLICY clear_all
    Jul 21 13:43:39 thinknix52 wpa_supplicant[2956]: wlp0s20f3: CTRL-EVENT-SIGNAL-CHANGE above=0 signal=-9999 noise=9999 txrate=0
    Jul 21 13:43:39 thinknix52 dhcpcd[41430]: wlp0s20f3: deleting default route via 192.168.1.1
    ...
    Jul 21 13:43:40 thinknix52 dhcpcd[41430]: wlp0s20f3: old hardware address: 80:38:fb:02:54:a9
    Jul 21 13:43:40 thinknix52 dhcpcd[41430]: wlp0s20f3: new hardware address: 92:64:36:03:6f:59
    ...
    Jul 21 13:43:41 thinknix52 systemd[1]: Stopping Network Manager...
    Jul 21 13:43:41 thinknix52 systemd[1]: home-manager-chrism.service: Deactivated successfully.
    Jul 21 13:43:41 thinknix52 systemd[1]: Stopped Home Manager environment for chrism.
    Jul 21 13:43:41 thinknix52 systemd[1]: network-setup.service: Deactivated successfully.
    Jul 21 13:43:41 thinknix52 wpa_supplicant[2956]: p2p-dev-wlp0s20: CTRL-EVENT-DSCP-POLICY clear_all
    Jul 21 13:43:41 thinknix52 systemd[1]: Stopped Networking Setup.
    Jul 21 13:43:41 thinknix52 dbus-daemon[2225]: [system] Activating via systemd: service name='org.freedesktop.nm_dispatcher' unit='dbus-org.freedesktop.nm-di>
    Jul 21 13:43:41 thinknix52 systemd[1]: Stopping WPA supplicant...
    Jul 21 13:43:41 thinknix52 dbus-daemon[2225]: [system] Activation via systemd failed for unit 'dbus-org.freedesktop.nm-dispatcher.service': Refusing activat>
    Jul 21 13:43:41 thinknix52 dhcpcd[41430]: wlp0s20f3: old hardware address: 92:64:36:03:6f:59
    Jul 21 13:43:41 thinknix52 dhcpcd[41430]: wlp0s20f3: new hardware address: 80:38:fb:02:54:a9
    Jul 21 13:43:41 thinknix52 wpa_supplicant[2956]: p2p-dev-wlp0s20: CTRL-EVENT-DSCP-POLICY clear_all
    Jul 21 13:43:41 thinknix52 wpa_supplicant[2956]: nl80211: deinit ifname=p2p-dev-wlp0s20 disabled_11b_rates=0
    ...
    Jul 21 13:43:41 thinknix52 wpa_supplicant[2956]: p2p-dev-wlp0s20: CTRL-EVENT-TERMINATING
    Jul 21 13:43:41 thinknix52 wpa_supplicant[2956]: wlp0s20f3: CTRL-EVENT-DSCP-POLICY clear_all
    Jul 21 13:43:41 thinknix52 dbus-daemon[2225]: [system] Activating via systemd: service name='org.freedesktop.nm_dispatcher' unit='dbus-org.freedesktop.nm-di>
    Jul 21 13:43:41 thinknix52 dbus-daemon[2225]: [system] Activation via systemd failed for unit 'dbus-org.freedesktop.nm-dispatcher.service': Refusing activat>
    Jul 21 13:43:41 thinknix52 wpa_supplicant[2956]: wlp0s20f3: CTRL-EVENT-DSCP-POLICY clear_all
    Jul 21 13:43:41 thinknix52 wpa_supplicant[2956]: nl80211: deinit ifname=wlp0s20f3 disabled_11b_rates=0
    Jul 21 13:43:41 thinknix52 wpa_supplicant[2956]: wlp0s20f3: CTRL-EVENT-TERMINATING
    Jul 21 13:43:41 thinknix52 systemd[1]: wpa_supplicant.service: Deactivated successfully.
    Jul 21 13:43:41 thinknix52 systemd[1]: Stopped WPA supplicant.
    Jul 21 13:43:41 thinknix52 systemd[1]: NetworkManager.service: Deactivated successfully.
    Jul 21 13:43:41 thinknix52 systemd[1]: Stopped Network Manager.
    Jul 21 13:43:41 thinknix52 systemd[1]: NetworkManager.service: Consumed 936ms CPU time, received 14.0K IP traffic, sent 48B IP traffic.
    Jul 21 13:43:41 thinknix52 systemd[1]: Stopped target Preparation for Network.
    ...
    Jul 21 13:45:09 thinknix52 systemd[1]: dhcpcd.service: State 'stop-sigterm' timed out. Killing.
    Jul 21 13:45:09 thinknix52 systemd[1]: dhcpcd.service: Killing process 41429 (dhcpcd) with signal SIGKILL.
    Jul 21 13:45:09 thinknix52 systemd[1]: dhcpcd.service: Killing process 41430 (dhcpcd) with signal SIGKILL.
    Jul 21 13:45:09 thinknix52 systemd[1]: dhcpcd.service: Killing process 41431 (dhcpcd) with signal SIGKILL.
    Jul 21 13:45:09 thinknix52 systemd[1]: dhcpcd.service: Killing process 41432 (dhcpcd) with signal SIGKILL.
    Jul 21 13:45:09 thinknix52 systemd[1]: dhcpcd.service: Killing process 41438 (dhcpcd) with signal SIGKILL.
    Jul 21 13:45:09 thinknix52 systemd[1]: dhcpcd.service: Main process exited, code=killed, status=9/KILL
    Jul 21 13:45:09 thinknix52 systemd[1]: dhcpcd.service: Failed with result 'timeout'.
    Jul 21 13:45:09 thinknix52 systemd[1]: Stopped DHCP Client.

  - (Why is dhcpd running under multiple pids?  Threading?  No clue.)

- Let's try to enable DHCP only on individual interfaces, because there is much
  ado about doing this in the generated hardware-configuration.nix and on
  Discourse, most of which I can't pretend to understand::

    #networking.useDHCP = true;
    networking.interfaces.enp0s31f6.useDHCP = true;                                networking.interfaces.wlp0s20f3.useDHCP = true;

  We see this outcome when we rebuild::

    reviving group 'dhcpcd' with GID 995
    reviving user 'dhcpcd' with UID 996
    setting up /etc...
    reloading user units for chrism...
    setting up tmpfiles
    reloading the following units: dbus.service
    restarting the following units: polkit.service
    starting the following units: accounts-daemon.service, network-setup.service, systemd-sysctl.service
    the following new units were started: dhcpcd.service, network-addresses-enp0s31f6.service, network-addresses-wlp0s20f3.service

  - But we see the same symptom at shutdown.

- Let's try to disable DHCP entirely.::

    #networking.useDHCP = true;
    #networking.interfaces.enp0s31f6.useDHCP = true;                               #networking.interfaces.wlp0s20f3.useDHCP = true;

  We see this outcome when we rebuild::
  
    stopping the following units: accounts-daemon.service, dhcpcd.service, network-addresses-enp0s31f6.service, network-addresses-wlp0s20f3.service, network-setup.service, systemd-sysctl.service
    NOT restarting the following changed units: systemd-fsck@dev-disk-by\x2dlabel-NIXBOOT.service
    activating the configuration...
    removing group ‘dhcpcd’
    removing user ‘dhcpcd’
    setting up /etc...
    removing obsolete symlink ‘/etc/dhcpcd.exit-hook’...
    removing obsolete symlink ‘/etc/systemd/network/40-wlp0s20f3.link’...
    removing obsolete symlink ‘/etc/systemd/network/40-enp0s31f6.link’...
    reloading user units for chrism...
    setting up tmpfiles
    reloading the following units: dbus.service
    restarting the following units: polkit.service
    starting the following units: accounts-daemon.service, network-setup.service, systemd-sysctl.service

  - We do not see the symptom at shutdown (presumably because dhcpd is no
    longer running, and thus doesn't need to be stopped).

  - I also have no issues with my wired or wireless obtaining IP addresses,
    presumably because I also run ``network-manager``.::

      networking.networkmanager.enable = true;

- So, what is the negative impact of omitting any information about ``useDHCP``
  in Nix config?  I have no idea.  My system probably wouldn't get an IP
  address if ``network-manager`` failed to start.  That's ok by me.

- Note that a second order effect on one of my systems was that I had to do
  this before I disabled ``useDHCP`` or I would have a similar stop job problem
  at shutdown for ``Network Manager Wait Online Enable``::

    # why must I do this?  I have no idea.
    systemd.services.NetworkManager-wait-online.enable = false;

  After disabling ``useDHCP`` entirely, I commented this out.
  
- I suspect there is just some subtle contention issue between ``network-manager``
  and ``dhcpd`` that isn't fatal, just annoying.
  
