================================================================================
NixOS 73: Building a NixOS Image for Raspberry Pi, Pt. 2 (Updating a Running Pi)
================================================================================

Recap
=====

The talky-script for this video is available in a link in the description
(https://github.com/mcdonc/.nixconfig/blob/master/videos/rpi2/script.rst).

In `part 1 of this series <https://youtu.be/9W6znVpxn1c>`_ (talky-script at
https://github.com/mcdonc/.nixconfig/blob/master/videos/rpi/script.rst), I got
a Pi Zero 2 W booting to NixOS after using a Nix flake to generate an image
file which I burned to an SD card.  I made sure wireless and HDMI worked.

In this video, I'll be solidifying the methods that we can use to update NixOS
on a Pi after we've got it running and contactable via our network.

In the first video, I used only a Pi Zero 2 W.  In the meantime, I've confirmed
that the SD card image generated by building the SD image as per the
instructions detailed in `part 1 of this series
<https://youtu.be/9W6znVpxn1c>`_ will boot each of a Pi Zero 2 W, a Pi 3 and Pi
4 fine.  Wireless and USB (at least a USB keyboard) work on all of those.  I've
used NixOS a Pi Zero 2 W, a Pi 3B+, and a Pi 4 to research this video at
various points.  I have not tested anything on a Pi 5 but it should work.  You
should be able to play along on any of them using the same image.

For the record, I will (still) not be testing GPIO, Bluetooth, Ethernet or
sound in this video.  Those will have to wait for another video.  That said, I
did verify that the Ethernet of a Pi 4 got an IP address from DHCP when I
plugged it into a switch, so it's almost certainly working fine.

Solved Mysteries and Added Conveniences
=======================================

In the first video, I ran across some mysteries and I did some things less than
optimally.

Automatic Booting
-----------------

In the first video, had an issue with my Zero 2 W not automatically booting.
I had to type ``boot`` on its console for it to start to boot Linux.  I thought
it might be an issue with that specific Zero 2 W, because it has been through
some tough times, but the issue actually turned out to be due to which devices
I have plugged into which of its micro USB ports.  If I plug the keyboard into
the micro USB closer to the HDMI, and the power into the the micro USB further
away from the HDMI, it will not boot.  If I reverse those, it boots fine.  Here
is the right orientation to allow an automatic boot:

.. image:: orientation.jpg

This is true of a second Pi Zero 2 W I tried as well, so likely every Pi Zero 2
W is this way.

Building on non-NixOS
---------------------

You can indeed use Ubuntu with Nix on it to build an image (I did it).  The
instructions are no different than those given in part 1, save for installing
Nix onto your Ubuntu machine first.

I did not try MacOS, nor, I've decided, will I.

Updating a running Pi remotely using non-NixOS may be a bit of a different
story.  In general, it's best to use NixOS as the system to generate an image
and update the running Pi later if you update remotely.  It's possible to use
other operating systems for this, but for sake of video brevity and research
time, I've decided that won't be going into any detail about doing it on
non-NixOS.

Using ``dd`` rather than Balena Etcher
--------------------------------------

I used Balena Etcher to write the image to an SD card the last time because it
seemed convenient, but it's not really if you're doing it a lot.

Instead, you can use ``dd``.  Issue this command (replace ``/dev/mysdcard``
with ``/dev/sda`` or ``/dev/sdb`` or whatever your card is present on) after
building the image as detailed in part 1::

  sudo dd if=result/sd-image/zero2.img of=/dev/mysdcard bs=1M conv=fsync status=progress

Note that NixOS automatically resizes the root partition to the entirety of the
SD card's free space upon first boot, no matter which burning method you use.

ZRAM
----

I've tried to give the booted system a little more headroom by increasing the
amount of compressed RAM swap space (ZRAM).  This is particularly helpful on
the Pi Zero 2 if you want to run ``nixos-rebuild`` on it.

Solving Today's Mystery: Updating the Pi as It's Running
========================================================

You can either generate Pi-local configuration files and manage the Pi
standalone via ``nixos-rebuild`` like any other NixOS system, or use
``deploy-rs`` to manage it remotely from another system.

Using Pi-Local Configuration Files
----------------------------------

This is probably the most practical way to start managing your NixOS Pi; treat
it like any other NixOS system and manage it via
``/etc/nixos/configuration.nix`` and ``nixos-rebuild``.  The downside is that
it doesn't work optimally on low-RAM-constrained systems like the Pi Zero 2 W
(512M).  But it does make use of binary caches, so typically nothing requires
compiling for ``aarch64``, so it's reasonably quick.

Once you've generated and booted the Pi image as per part 1, log into the Pi
and use it to generate ``/etc/configuration.nix`` and
``/etc/hardware-configuration.nix``::

  sudo nixos-generate-config

Then copy the stuff from ``zero2w.nix`` in the `repository
<https://github.com/mcdonc/nixos-pi-zero-2>`_ into your Pi's
``/etc/configuration.nix`` to match the current state of the system.  Get rid
of ``sdImage`` stuff and ``nixpkgs.hostPlatform.system`` /
``nixpkgs.buildPlatform.system`` and include ``./hardware-configuration.nix``
instead of ``./sd-image.nix``.

For example, ``/etc/nixos/configuration.nix`` looks like this when I'm done
with it:

.. code-block:: nix

    { config, lib, pkgs, ... }:

    {
      imports =
        [ # Include the results of the hardware scan.
          ./hardware-configuration.nix
        ];

      # ! Need a trusted user for deploy-rs.
      nix.settings.trusted-users = ["@wheel"];
      system.stateVersion = "24.05";

      documentation.nixos.enable = false;

      services.zram-generator = {
        enable = true;
        settings.zram0 = {
          compression-algorithm = "zstd";
          zram-size = "ram * 2";
        };
      };

      # Keep this to make sure wifi works
      hardware.enableRedistributableFirmware = lib.mkForce false;
      hardware.firmware = [pkgs.raspberrypiWirelessFirmware];

      boot = {
        initrd.availableKernelModules = ["xhci_pci" "usbhid" "usb_storage"];

        loader = {
          grub.enable = false;
          generic-extlinux-compatible.enable = true;
          timeout = 2;
        };

        # Avoids warning: mdadm: Neither MAILADDR nor PROGRAM has been set.
        # This will cause the `mdmon` service to crash.
        # See: https://github.com/NixOS/nixpkgs/issues/254807
        swraid.enable = lib.mkForce false;
      };

      networking = {
      };

      services.dnsmasq.enable = true;

      networking = {
        interfaces."wlan0".useDHCP = true;
        wireless = {
          enable = true;
          interfaces = ["wlan0"];
          # ! Change the following to connect to your own network
          networks = {
            "ytvid-rpi" = { # SSID
              psk = "ytvid-rpi"; # password
            };
          };
        };
      };

      # Enable OpenSSH out of the box.
      services.sshd.enable = true;

      # NTP time sync.
      services.timesyncd.enable = true;

      # ! Change the following configuration
      users.users.chrism = {
        isNormalUser = true;
        home = "/home/chrism";
        description = "Chris McDonough";
        extraGroups = ["wheel" "networkmanager"];
        # ! Be sure to put your own public key here
        openssh = {
          authorizedKeys.keys = [
            "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOLXUsGqUIEMfcXoIiiItmGNqOucJjx5D6ZEE3KgLKYV ednesia"
          ];
        };
      };

      security.sudo = {
        enable = true;
        wheelNeedsPassword = false;
      };
      # ! Be sure to change the autologinUser.
      services.getty.autologinUser = "chrism";

     environment.systemPackages = with pkgs; [
        htop
        vim
        emacs
        ripgrep
        btop
        (python311.withPackages (p:
          with p; [
            python311Packages.rpi-gpio
            python311Packages.gpiozero
            python311Packages.pyserial
          ]))
        usbutils
        tmux
        git
        dig
        tree
        bintools
        lsof
        pre-commit
        file
        bat
        ethtool
        minicom
        fast-cli
        nmap
        openssl
        dtc
        zstd
        neofetch
      ];
    }

Update the nixpkgs channel on the Pi::

  sudo nix-channel --update

Run ``nixos-rebuild switch`` on the Pi::

  sudo nixos-rebuild switch

This will eat into swap on the Pi Zero 2 W, and OOM-ed on me the first time I
ran it.  But because ``nixos-rebuild`` saves all its work and is idempotent on
a second and subsequent run, you can just run it again.  Not ideal, but it
works, and isn't an issue on machines with >1GB RAM AFAICT.

Log::

  $ sudo nixos-rebuild switch -v

  # .. elided ..

  building '/nix/store/9s96s7yixj8sh5aryj4f7q1935vqqrka-nixos-system-nixos-pi-24.05pre588909.13aff9b34cc3.drv'...
  $ sudo nix-env -p /nix/var/nix/profiles/system --set /nix/store/skbjwqv05b6ny782hyfrbzk12w2xi8ab-nixos-system-nixos-pi-24.05pre588909.13aff9b34cc3
  $ sudo systemd-run -E LOCALE_ARCHIVE -E NIXOS_INSTALL_BOOTLOADER= --collect --no-ask-password --pty --quiet --same-dir --service-type=exec --unit=nixos-rebuild-switch-to-configuration --wait true
  Using systemd-run to switch configuration.
  $ sudo systemd-run -E LOCALE_ARCHIVE -E NIXOS_INSTALL_BOOTLOADER= --collect --no-ask-password --pty --quiet --same-dir --service-type=exec --unit=nixos-rebuild-switch-to-configuration --wait /nix/store/skbjwqv05b6ny782hyfrbzk12w2xi8ab-nixos-system-nixos-pi-24.05pre588909.13aff9b34cc3/bin/switch-to-configuration switch
  stopping the following units: audit.service, boot-firmware.mount, dnsmasq.service, kmod-static-nodes.service, logrotate-checkconf.service, mount-pstore.service, network-local-commands.service, network-setup.service, nscd.service, resolvconf.service, systemd-modules-load.service, systemd-oomd.service, systemd-oomd.socket, systemd-sysctl.service, systemd-timesyncd.service, systemd-udevd-control.socket, systemd-udevd-kernel.socket, systemd-udevd.service, systemd-update-done.service, systemd-vconsole-setup.service, systemd-zram-setup@zram0.service, zfs-import.target, zfs-mount.service, zfs-share.service, zfs-zed.service, zfs.target, zpool-trim.timer
  NOT restarting the following changed units: -.mount, getty@tty1.service, systemd-journal-flush.service, systemd-logind.service, systemd-random-seed.service, systemd-remount-fs.service, systemd-update-utmp.service, systemd-user-sessions.service, user-runtime-dir@1000.service, user@1000.service
  activating the configuration...
  setting up /etc...
  # ... elided ...
  restarting the following units: network-addresses-wlan0.service, sshd.service, systemd-journald.service, wpa_supplicant-wlan0.service
  starting the following units: audit.service, dnsmasq.service, kmod-static-nodes.service, logrotate-checkconf.service, mount-pstore.service, network-local-commands.service, network-setup.service, nscd.service, resolvconf.service, systemd-modules-load.service, systemd-oomd.socket, systemd-sysctl.service, systemd-timesyncd.service, systemd-udevd-control.socket, systemd-udevd-kernel.socket, systemd-update-done.service, systemd-vconsole-setup.service, systemd-zram-setup@zram0.service
  the following new units were started: sysinit-reactivation.target, systemd-tmpfiles-resetup.service

Using ``deploy-rs`` With Remote Configuration
---------------------------------------------

I also got ``deploy-rs`` working in various ways to update the Pi remotely with
new packages instead of managing it locally with ``nixos-rebuild``.  This is
most useful on memory-constrained systems like the Pi Zero 2 W, or if you want
to manage many Pis from a single system.

Working Method 1: Build locally, use aarch64 version of ``deploy-rs`` on target
+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

The most foolproof method of managing the Pi remotely via ``deploy-rs`` is to
build locally, and use the ``aarch64`` version of ``deploy-rs`` on the target.
It's slow (it builds using ``qemu``, and doesn't seem to pull much down from
any binary cache) but it works and doesn't require a significant amount of
memory on the target system.  I tried this in part 1 but it wasn't working
because I hadn't enabled ``aarch64-linux`` binary emulation on my host system.

On NixOS host system, to set up ``aarch64`` emulation, you have to enable this
in your ``configuration.nix``::

   # run aarch64 binaries via qemu
   boot.binfmt.emulatedSystems = [ "aarch64-linux" ];

(It's apparently possible to use a non-NixOS host system too; see
https://packages.ubuntu.com/bionic/qemu-user-binfmt via
https://github.com/serokell/deploy-rs/issues/200).

You needn't make any changes to the ``nixos-pi-zero-2-w`` repository files
except to change the ``zero2w.nix`` file to reflect the packages and
configuration changes you want.

Then running ``deploy-rs`` will have the same effect as the ``nixos-rebuild``
we did in the prior section, except all the heavy lifting is done on the host
system and not on the Pi.

Log::

   $ nix run github:serokell/deploy-rs ".#zero2w" -- --ssh-user chrism --hostname 192.168.1.172
   🚀 ℹ️ [deploy] [INFO] Running checks for flake in .
   warning: Git tree '/home/chrism/projects/nixos-pi-zero-2' is dirty
   warning: unknown flake output 'deploy'
   🚀 ℹ️ [deploy] [INFO] Evaluating flake in .
   warning: Git tree '/home/chrism/projects/nixos-pi-zero-2' is dirty
   🚀 ℹ️ [deploy] [INFO] The following profiles are going to be deployed:
   [zero2w.system]
   user = "root"
   ssh_user = "chrism"
   path = "/nix/store/psygac4lz9jgdj8qi9wv0kfg4xmpck72-activatable-nixos-system-nixos-24.05.20240225.2a34566"
   hostname = "zero2w"
   ssh_opts = []

   🚀 ℹ️ [deploy] [INFO] Building profile `system` for node `zero2w`
   🚀 ℹ️ [deploy] [INFO] Copying profile `system` to node `zero2w`
   🚀 ℹ️ [deploy] [INFO] Activating profile `system` for node `zero2w`
   🚀 ℹ️ [deploy] [INFO] Creating activation waiter
   ⭐ ℹ️ [activate] [INFO] Activating profile
   👀 ℹ️ [wait] [INFO] Waiting for confirmation event...
   activating the configuration...
   setting up /etc...
   reloading user units for chrism...
   restarting sysinit-reactivation.target
   reloading the following units: dbus.service
   the following new units were started: sysinit-reactivation.target, systemd-tmpfiles-resetup.service
   ⭐ ℹ️ [activate] [INFO] Activation succeeded!
   ⭐ ℹ️ [activate] [INFO] Magic rollback is enabled, setting up confirmation hook...
   👀 ℹ️ [wait] [INFO] Found canary file, done waiting!
   ⭐ ℹ️ [activate] [INFO] Waiting for confirmation event...
   🚀 ℹ️ [deploy] [INFO] Success activating, attempting to confirm activation
   🚀 ℹ️ [deploy] [INFO] Deployment confirmed.

Working Method 2:  Build remotely
+++++++++++++++++++++++++++++++++

This will cause the Pi to build all the packages even though we use
``deploy-rs``.  You needn't set up ``aarch64-linux`` binary emulation on your
host for this method or any other form of binary emulation.  This probably
won't work reliably for very-low-memory systems like the Pi Zero 2 but it's
probably fine for Pi 3/4/5.  Has similar memory requirements to using local
config files on the Pi.

But I wouldn't recommend this; it's saner to just manage a
``configuration.nix`` on the Pi instead; it effectively does the same thing.
But it can be useful if you're trying to troubleshoot or work around bugs in
``deploy-rs`` cross-compiles.

In ``nixos-pi-zero-2-w/flake.nix``::

  deploy = {
    user = "root";
    nodes = {
      zero2w = {
        hostname = "zero2w";
        profiles.system.path =
          deploy-rs.lib.aarch64-linux.activate.nixos self.nixosConfigurations.zero2w;
        # add this magic
        remoteBuild = true;
      };
    };
  };

Non-Working Method: Build locally, use x86_64 version of ``deploy-rs`` on target
++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

This is supposed to be faster than the first ``aarch64`` method of
``deploy-rs`` as gleaned from
https://artemis.sh/2023/06/06/cross-compile-nixos-for-great-good.html .  I
couldn't make it work, though.  At the moment, it fails with a segfault in
``qemu`` for me.

In flake.nix::

  deploy = {
    user = "root";
    nodes = {
      zero2w = {
        hostname = "zero2w";
        profiles.system.path =
          # change this
          # deploy-rs.lib.aarch64-linux.activate.nixos self.nixosConfigurations.zero2w;
          # to this
          deploy-rs.lib.x86_64-linux.activate.nixos self.nixosConfigurations.zero2w;
      };
    };
  };

In zero2w.nix, uncomment::

  # run x86_64 binaries via qemu
  boot.binfmt.emulatedSystems = [ "x86_64-linux" ];

And comment::

  #nixpkgs.buildPlatform.system = "x86_64-linux";

Log::

   $ nix run github:serokell/deploy-rs ".#zero2w" -- --ssh-user chrism --hostname 192.168.1.171
   🚀 ℹ️ [deploy] [INFO] Running checks for flake in .
   warning: Git tree '/home/chrism/projects/nixos-pi-zero-2' is dirty
   warning: unknown flake output 'deploy'
   🚀 ℹ️ [deploy] [INFO] Evaluating flake in .
   warning: Git tree '/home/chrism/projects/nixos-pi-zero-2' is dirty
   🚀 ℹ️ [deploy] [INFO] The following profiles are going to be deployed:
   [zero2w.system]
   user = "root"
   ssh_user = "chrism"
   path = "/nix/store/4n10n3v9p0hadw8nha12djyc6d3p4k17-activatable-nixos-system-nixos-24.05.20240225.2a34566"
   hostname = "zero2w"
   ssh_opts = []

   🚀 ℹ️ [deploy] [INFO] Building profile `system` for node `zero2w`
   🚀 ℹ️ [deploy] [INFO] Copying profile `system` to node `zero2w`
   🚀 ℹ️ [deploy] [INFO] Activating profile `system` for node `zero2w`
   🚀 ℹ️ [deploy] [INFO] Creating activation waiter
   qemu-x86_64: QEMU internal SIGSEGV {code=MAPERR, addr=0x20}
   qemu-x86_64: QEMU internal SIGSEGV {code=MAPERR, addr=0x20}
   🚀 ❌ [deploy] [ERROR] Activating over SSH resulted in a bad exit code: Some(255)
   🚀 ℹ️ [deploy] [INFO] Revoking previous deploys
   🚀 ❌ [deploy] [ERROR] Deployment failed, rolled back to previous generation

Conclusion
==========

Now I know how to manage my NixOS on Pi without reflashing an image every time
I want to change its configuration or add software to it.  I'm not sure whether
I want to use ``deploy-rs`` or just manage my Pis locally yet; it's nice to
have both options.

In a followup video, with any luck, I will ensure that Ethernet, Bluetooth,
sound, GPIO and USB storage work on a Pi 4.
