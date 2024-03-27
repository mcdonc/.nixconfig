======================================================
NixOS 84: !@^&#* NixOS Made My Other Linux Unbootable!
======================================================

Companion to video at

This text script available via link in the video description.

See the other videos in this series by visiting the playlist at
https://www.youtube.com/playlist?list=PLa01scHy0YEmg8trm421aYq4OtPD8u1SN

Script
------

Using the NixOS graphical installer available on the `ISO images
<https://nixos.org/download/>`_ can in some circumstances make it seem like an
Linux that existed on the same system before the NixOS install is unbootable.

At this point, if you already know what I mean, and all you want is
instructions on how to fix it, please read the description of this video.  If
you want to know what's actually happening, keep watching.

For better or worse, on EFI systems, the graphical installer chooses, on EFI
systems, to use `systemd-boot <https://systemd.io/BOOT/>`_ to provide a boot
menu that allows booting to both NixOS and any existing operating systems on
the same host.  While this works fine if the only other operating system you
have installed on the host is Windows, it can be a problem if you've got
another Linux distribution already installed on the machine.

Most other Linux systems use `GRUB <https://www.gnu.org/software/grub/>`_ as a
boot menu system, and NixOS, when it installs ``systemd-boot`` can make it
appear that it has destroyed your ability to get to your other Linux via a GRUB
menu.  It hasn't, but it sure seems like it.

Note: this problem is only related to EFI systems, if your system is MBR, you
have a different problem, because NixOS uses GRUB as a boot loader on MBR
systems.

Here's a system with an existing installation of AVLinux on it.  I'll install
NixOS on it, putting it on an existing (empty) partition of the same hard disk
that has AVLinux.

When the installer finishes, and I reboot, I will be shown the ``systemd-boot``
menu, and it will appear that the only system that I can boot to is NixOS.  But
don't worry, AVLinux isn't gone.

The quickest potential way to get back into an existing Linux install is to
choose "Reboot Into Firmware Interface", which will dump you into your BIOS.
From there, choose the boot device that is associated with your other Linux.
In my case, it's "MX21."  Whatever it is, it's *not* "Linux Boot Manager",
that's NixOS and systemd-boot.

This is pretty unsatisfactory, though, because it's a lot more keystrokes to go
through.  You need to choose "Reboot into Firmware Interface", then choose your
other EFI entry in your BIOS, and you're then dumped into your other Linux'
GRUB, so it's three boot menus (systemd-boot, your BIOS, then GRUB) to boot to
your other Linux instead of one.  Or maybe the menu entry for your other Linux
doesn't appear anywhere in your BIOS EFI list for some reason.  We can fix
either scenario by telling NixOS to use GRUB instead of ``systemd-boot`` as a
boot loader.  We need to boot into NixOS to do this and cause ``nixos-rebuild
switch`` to be done while GRUB is configured as the boot loader, and "OS
probing" is turned on.

Change your ``configuration.nix`` to comment out any lines that start with
``boot.loader.systemd-boot``, then add the following::

   boot.loader.grub.enable = true;
   boot.loader.grub.device = "nodev";
   boot.loader.grub.efiInstallAsRemovable = true;
   boot.loader.grub.efiSupport = true;
   boot.loader.grub.useOSProber = true;

And run ``nixos-rebuild switch``.

At this point, you will be able to boot to either NixOS or your other Linux via
a single GRUB menu, and updates to the boot menu files from either system will
be respected and reflected at reboot time.

You may be clever enough that you have already tried this, and you ran into an
error messages like "warning: this GPT partitional label contains no BIOS Boot
Partiton; embedding won't be possible" and "GRUB can only be installed in this
setup by using blocklists" and "installation of GRUB on /dev/sda failed:
Inappropriate ioctl for device".

That means it's complaining that it can't install GRUB to your hard disk.
Luckily, it doesn't have to; GRUB is already installed.  We can sidestep the
problem by telling NixOS to use ``nodev`` as the boot device.  This causes
NixOS to only change any existing GRUB menu files, but not to try to actually
install the GRUB boot loader to any partition.::

   # comment this out
   # boot.loader.grub.device = "/dev/sda";

   # and replace it with this
   boot.loader.grub.device = "nodev";

If for some reason that doesn't work, as a last-ditch effort, take a look at
`this stackoverflow entry
<https://askubuntu.com/questions/1314111/convert-mbr-partition-to-gpt-without-data-loss/1315273#1315273>`_
but ignore any advice to do ``grub-install`` and anything past it; that's
handled for us by ``nixos-rebuild switch``.

I also able to make AVLinux boot in this scenario by adding a new "BIOS boot"
partition with code ``ef02`` of about 100M (I destroyed a swap partition so I
could do that), and pointing ``boot.loader.grub.device = "dev/sda"`` and
rerunning ``nixos-rebuild switch``.  It reinstalled GRUB and I wound up at the
same place as the ``nodev`` GRUB install, except I had a useless partition
hanging around on my hard disk.


