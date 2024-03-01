===========================================================================
NixOS 74: Building a NixOS Image for Raspberry Pi, Pt. 3 (Hardware Support)
===========================================================================

Recap
=====

The talky-script for this video is available in a link in the description
(https://github.com/mcdonc/.nixconfig/blob/master/videos/rpi3/script.rst).

In `part 2 of this series <https://youtu.be/9W6znVpxn1c>`_ (talky-script at
https://github.com/mcdonc/.nixconfig/blob/master/videos/rpi2/script.rst), I
managed to be able to update the software on our NixOS image while it's
running.

In this video, I'll be reporting my findings about trying to get hardware to
work.  Spoiler alert: it's not good news.

Repository Changes
==================

The repository at https://github.com/mcdonc/nixos-pi-zero-2 (despite the name)
now has explicit Pi 4 support.  It actually may now support Pi 4 a bit better
than the Zero 2 W.

To build a Pi 4 image::

  nix build -L ".#nixosConfigurations.pi4.config.system.build.sdImage"

To build a Zero 2 W image::

  nix build -L ".#nixosConfigurations.zero2w.config.system.build.sdImage"

In either case, the image ends up in ``result/sd-image/pi.img`` now.

The file that needs changing to change your user and networking is now
``common.nix`` rather than ``zero2w.nix``.

Some differences in the kernels used, and the configurations of each device
have been made.
  
Kernel
------

The Pi 4 kernel is not mainline anymore, it's::
  
   kernelPackages = lib.mkDefault pkgs.linuxKernel.packages.linux_rpi4;

This is apparently the kernel that ships with Raspberry Pi OS.

Separate Configs for Zero 2 W and 4
-----------------------------------

For the Pi 4, we now use a configuration from the ``nixos-hardware`` repository
at https://github.com/NixOS/nixos-hardware/tree/master/raspberry-pi/4

There are no Pi 3/Zero 2/Pi 5 configurations in nixos-hardware yet, so we don't
use one for the 2W.

The Pi4 image will not boot on a Zero 2 W.

Hardware Results
================

At the moment (Feb 29, 2024), these are the results of trying to make various
bits of hardware work on both the Zero 2 W and the Pi 4.

GPIO
----

The image builder produces a Python that has ``RPi.GPIO`` installed.  User must
be a member of the "gpio" group to not use through sudo (this is also handled by the image builder).

``RPi.GPIO`` works on the Pi 4.  It can blink an LED.

It does not work on the Zero 2 W.  We can't import the library::

  [chrism@nixos-zero2w:~]$ python
  Python 3.11.8 (main, Feb  6 2024, 21:21:21) [GCC 13.2.0] on linux
  Type "help", "copyright", "credits" or "license" for more information.
  >>> import RPi.GPIO
  Traceback (most recent call last):
    File "<stdin>", line 1, in <module>
    File "/nix/store/q8b68hcdk4dalivmv18fdsxp3yc56jqb-python3-aarch64-unknown-linux-gnu-3.11.8-env/lib/python3.11/site-packages/RPi/GPIO/__init__.py", line 23, in <module>
      from RPi._GPIO import *
  RuntimeError: This module can only be run on a Raspberry Pi!

There are a number of other ways to control the GPIO pins, including alternate
Python libraries, but I have not tried them.

Sound on the Pi 4
-----------------

No worky.  The ``nixos-hardware`` repository exposes a flag named
``hardware.raspberry-pi."4".audio.enable`` that, if set true, should manage a
device tree entry and set up PulseAudio for us.  It does not work::

    device-tree-overlays> Applying overlay audio-on-overlay to bcm2711-rpi-4-b.dtb... DTOVERLAY[error]: can't find symbol 'audio'
    error: builder for '/nix/store/ghjrs8vvml69i9ryhkscsas82vypfmac-device-tree-overlays.drv' failed with exit code 1;
           last 7 log lines:
           > ./broadcom -> /nix/store/7dy48h4vw02jgbb8rjqc7kazm9f0zs9r-device-tree-overlays/./broadcom
           > './broadcom/bcm2711-rpi-400.dtb' -> '/nix/store/7dy48h4vw02jgbb8rjqc7kazm9f0zs9r-device-tree-overlays/./broadcom/bcm2711-rpi-400.dtb'
           > './broadcom/bcm2711-rpi-4-b.dtb' -> '/nix/store/7dy48h4vw02jgbb8rjqc7kazm9f0zs9r-device-tree-overlays/./broadcom/bcm2711-rpi-4-b.dtb'
           > Applying overlay rpi4-cma-overlay to bcm2711-rpi-4-b.dtb... ok
           > Applying overlay rpi4-vc4-fkms-v3d-overlay to bcm2711-rpi-4-b.dtb... ok
           > Applying overlay rpi4-cpu-revision to bcm2711-rpi-4-b.dtb... ok
           > Applying overlay audio-on-overlay to bcm2711-rpi-4-b.dtb... DTOVERLAY[error]: can't find symbol 'audio'
           For full logs, run 'nix log /nix/store/ghjrs8vvml69i9ryhkscsas82vypfmac-device-tree-overlays.drv'.
    error: 1 dependencies of derivation '/nix/store/354qkiyi27d8fh1dqfcsp78clx5kpvpv-nixos-system-nixos-pi4-24.05.20240225.2a34566.drv' failed to build
    error: 1 dependencies of derivation '/nix/store/mzzkl1xsxw6ik1vghaifk0k2x5pldwib-ext4-fs.img-aarch64-unknown-linux-gnu.drv' failed to build
    error: 1 dependencies of derivation '/nix/store/24hz6mmx2f302gxl7hcs3mm6wiylzcw1-pi.img-aarch64-unknown-linux-gnu.drv' failed to build

I additionally have the normal NixOS sound-related flags in the config:

.. code-block:: nix

    sound.enable = true;
    hardware.pulseaudio.enable = true;
                
This should produce, I think, a running PulseAudio daemon?  For some reason, it
does not.  THis is the result of trying to use ``alsamixer``::

  chrism@nixos-pi4:~]$ sudo alsamixer
  ALSA lib pulse.c:242:(pulse_connect) PulseAudio: Unable to connect: Connection refused
  cannot open mixer: Connection refused
    
I'm sure these issues can be fixed.  Somehow.  By someone.

Ethernet on the Pi 4
--------------------

When you plug a cable into the Ethernet jack of a Pi 4, it does obtain an IP
address.  But it's only IPv6!  Also can't seem to get both ethernet and
wireless working at the same time.  When both are active, the machine is
uncontactable remotely.

Bluetooth
---------

A hardware configuration issue still prevents Bluetooth from working on either
the Pi 4 or the Zero 2 W::

  [   16.380638] Bluetooth: hci0: command 0xfc18 tx timeout
  [   24.540647] Bluetooth: hci0: BCM: failed to write update baudrate (-110)
  [   24.540692] Bluetooth: hci0: Failed to set baudrate
  [   26.556673] Bluetooth: hci0: command 0x0c03 tx timeout
  [   34.780641] Bluetooth: hci0: BCM: Reset failed (-110)


USB Storage
-----------

Works on Pi 4.  Sticking in a USB stick and mounting it::

   [chrism@nixos-pi4:~]$ sudo mkdir /mnt
   [chrism@nixos-pi4:~]$ sudo mount /dev/sda1 /mnt
   [chrism@nixos-pi4:~]$ ls /mnt/
    amnesia.tar.gz
    ...

Conclusions
===========

It's not roses.

The experience of NixOS on a specific RPi device is not near the experience of
using the same one under Raspberry Pi OS, although the ``nixos-hardware`` stuff
related to Pi 4 does help.

In a better world, NixOS configurations wouldn't be pieced out into snippets
that bitrot over time and can't throw an error because they're wiki pages
instead of things that people run. They would all be committed to executable
code as repeatable builds, is the promise of NixOS. Even if those concrete
executable bits stopped working over time due to kernel or user-space changes,
at least they not work in one way we could all reproduce instead of
mysteriously not working in a hundred different ways after being cobbled
together via cut and paste within a thousand different configurations.

The good news is that RPi devices are fixed targets.  It's not like PC hardware
that has configurations that need to be massaged depending on hundreds of
different motherboard chipsets.  There are only five or six possible
configurations, so, in theory, once a configuration was done, it would stay
done.

But still, trying to get there is frustrating.  None of the snippets in the
Wiki at https://nixos.wiki/wiki/NixOS_on_ARM/Raspberry_Pi related to Pi GPIO,
sound, or Bluetooth work anymore.  At least on a Pi 4 or Zero 2 W.  It's mostly
misinformation, and there is no other credible source of NixOS-related device
tree information for specific devices I can find to try to cobble into a
completely working config.

To my shame, it won't be me who powers through this; my stagecoach has turned
into a pumpkin.
