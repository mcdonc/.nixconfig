==================================================
NixOS 83: NixOS as a Music/Audio Production System
==================================================

Companion to video at

This text script available via link in the video description.

See the other videos in this series by visiting the playlist at
https://www.youtube.com/playlist?list=PLa01scHy0YEmg8trm421aYq4OtPD8u1SN

Script
------

Linux can be a pretty competent audio production system.  But it's notoriously
tricky to get set up for first time use, especially if you need extremely
low-latency near-realtime monitoring through an effects stack.

It's easier to get an open-source Linux audio production system set up using
NixOS than, let's say, using Ubuntu or Arch.  I know this because I've tried
all three.  (I mean, you know, delta the year it took me to be able to read and
write Nix-the-language proficiently.)  Even if you can't read or write Nix yet,
and you're willing to cargo cult shit without understanding it or questioning
it, it's falling-off-a-log easy to make the same changes I'm going to make to a
stock NixOS system to repeat what I show here.

We're going to do the following:

- Set up Pipewire under NixOS such that it emulates ALSA, PulseAudio, and JACK.

- Set up low-level kernel and userspace configuration using a project named
  `Musnix <https://github.com/musnix/musnix/tree/master>`_.  This will give us
  a realtime kernel, and will configure various PAM limits and udev rules that
  make the system run more predictably and with less latency under audio
  workloads.  It will also configure global and user-specific VST and LV2
  search paths.

- Record and play back some audio using Ardour.

- Get some LV2 plugins installed and usable in Ardour.

- Record and play back some audio using Audacity.

- Make sure ``qjackctl`` works.

- Install and switch to a lightweight desktop environment.

Before we start, please note that if you rely heavily on software to do some
crucial part of your audio work that is not open source, and that software is
distributed only as a binary blob from its distributor (an installer for it is
not in ``nixpkgs`)`, it will be more difficult to get it running on NixOS than
to get it running on, say, Ubuntu.  Software that falls into this category
includes Harrison Mixbus.  Mixbus is packaged in a proprietary distribution
format, and an installer has not been created yet for NixOS.  That said,
installers do exist for Reaper, Bitwig, and other proprietary DAWs.  There are
also many libraries of VST/LV2 plugins packaged for Nix in ``nixpkgs``, but if
you've got commercial ones that aren't, you should be able to drop them into
the usual locations and they should just work, at least if they work on other
Linux distros.

I'm going to do this on a virtual machine, so I won't be demonstrating any
realtime effects monitoring, as the latency caused by the virtualization makes
it pointless.  However, on real hardware, it's pretty much as good as it's
gonna get.  Guitarix and its plugins (which require good monitoring latency)
are packaged for NixOS, so it is a good candidate to try out.  I have not done
so.

Also, for the record, we will compile a kernel during this process.  If your
machine isn't high-octane, or and you plan on doing this more than one time or
on more than one machine, you may want to get a `Cachix <https://cachix.org>`_
account and set up cachix so that it caches the result of your builds.

Also also, I'm going to use a NixOS flake to configure our system.  If you
haven't yet switched over to flakes, apologies, but you might want to check out
one or both of my videos entitled `NixOS 63: Install NixOS 23.11 and Use Flakes
Out Of the Box <https://youtu.be/hoB0pHZ0fpI>`_ or `NixOS 40: Converting an
Existing NixOS Configuration To Flakes <https://youtu.be/Hox4wByw5pY>`_.

Also also also: I've run through the steps of this video once before on this
virtual host, so, if you follow along, don't be suprised if the output of, for
example, ``nixos-rebuild`` is not exactly what mine is, because your system
will likely need to do more work than mine to get to the same result due to my
prior work.

Also, also, also, also: a shout out to my friend Tres, by whom this video was
inspired.

The VM I'm using to demonstrate this is in pretty close to a stock
post-Nix-installer state.  It is unchanged in any meaningful way, so we are
more or less starting from scratch.

Let's prepare:

- Enable audio input on the audio VM.

- Get NixOS set up in flake mode.  Please refer to one of the flakes-related
  videos I just mentioned to do so.

- Enable Pipewire with JACK.

- Run ``uname -a`` before we do a rebuild so we can see that the kernel version
  changed.

We'll get musnix configured.  Initial settings::

   musnix.enable = true;
   musnix.soundcardPciId = "00:05.0";
   musnix.kernel.realtime = true;
   musnix.rtirq.enable = true;

Unused: ``musnix.alsaSeq.enable`` (alsa seuqencer kernel modules),
``musnix.ffado.enable`` (firewire), and other various in-the-weeds settings.

``musnix.enable`` causes sysctl vm.swappiness to be set to 10, sets a
"threadirqs" kernel param, sets up environment variables that help applications
find VST/LV2/etc plugins, sets the CPU frequency governor to "performance",
sets ``limits.conf`` settings for the audio group, and sets up udev rules for
the audio group.  All of this will sound familar to people who have done audio
work on Linux before.

``musnix.kernel.realtime`` causes a ``PREEMPT_RT`` kernel to be compiled and
used at next boot.  To be honest, I'm not really sure this is really even
required these days to get acceptable monitoring latency.  But we're doing it
anyway.  If it turns out to be a problem, or unnecssary, we can always later
set it to false, run ``nixos-rebuild`` again, and get back to our stock kernel.

``musnix.rtirq.enable`` sets up ``/etc/rtirq.conf`` and causes rtirq to be
executed at boot (IRQ thread tuning for realtime kernels).  It's only respected
if ``musnix.kernel.realtime`` is true.

``musnix.soundcard.PciId`` causes the latency timer for the named sound card to
be set.  I have no idea what this means.  But ``nix-shell -p pciutils`` then
``lspci | grep -i audio`` is what told us the PCI id of our VM's sound card.

I'll nixos rebuild.  When done, I'll reboot the VM.

After reboot:

- Run ``uname -a`` and ``systemctl status rtirq``.

- Try ardour.

- Add ``chrism`` to "audio" group and rebuild, relogin.

- Try ardour again.

- Add qjackctl, fire it up with ardour.

- Scan for plugins.

- Add calf, tap-plugins, x42-plugins, helm to system packages.

- Scan for plugins.
  
- Try audacity, do a recording via Pulse.

- Cinnamon::

   services.xserver.displayManager.lightdm.enable = true;
   services.xserver.desktopManager.cinnamon.enable = true;
   services.xserver.displayManager.defaultSession = "cinnamon";

- Rebuild and reboot.

- Audacity and ardour still fire up.
  
