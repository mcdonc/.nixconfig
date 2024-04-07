====================================================
NixOS 85: NixOS as a Music Production System, Part 2
====================================================

Companion to video at

This text script available via link in the video description.

See the other videos in this series by visiting the playlist at
https://www.youtube.com/playlist?list=PLa01scHy0YEmg8trm421aYq4OtPD8u1SN

Script
------

In my video entitled `#83 NixOS as a Music Production System
<https://www.youtube.com/watch?v=_M_vSwGGVzY>`_, I got PipeWire and Musnix set
up for low latency recording and monitoring, and I got Ardour and Audacity
working with some plugins.

In this followup video, I will take you through some configuration steps to
attempt to prevent xruns, further reduce monitoring latency, and we'll set up
some commercial VST plugins.  I'll be using rtcqs, changing Musnix rtirq
config, disusing the low-latency kernel, using a new Musnix feature for rtcqs,
measuring sound card internal latency, and adding wireplumber, xruncounter, and
yabridge for VSTs.

I'm going to use a NixOS flake to configure our system.  If you haven't yet
switched over to flakes, apologies, but you might want to check out one or both
of my videos entitled `NixOS 63: Install NixOS 23.11 and Use Flakes Out Of the
Box <https://youtu.be/hoB0pHZ0fpI>`_ or `NixOS 40: Converting an Existing NixOS
Configuration To Flakes <https://youtu.be/Hox4wByw5pY>`_.

I'm going to start in a place that is close to where I left off in video #83.
In that video, I used a virtual machine, so I couldn't really demonstrate what
performance and monitoring latency was like in the real world.  But in this
video, I'll be configuring NixOS on real hardware, a Thinkpad P51 laptop.  It's
a six-year-old four-core 2.8Ghz Intel i7-7700HQ with 48MB of RAM.  It gets
scores of about 1300 single-core and 4400 multi-core in Geekbench 6.

Stuff
-----

A new-ish Musnix feature (new since my last video) provides access to a script
named `rtcqs <https://codeberg.org/rtcqs/rtcqs>`_ .  This script analyzes your
system configuration and offers suggestions about changes that could be made to
reduce audio latency.

.. code-block:: nix

   musnix.rtcqs.enable = true;

I've set up a program named ``xruncounter`` to try to generate xruns.  xruns
happen when the operating system cannot supply audio software like Ardour with
data fast enough.  I haven't seen ``xruncounter`` generate any xruns under any
configuration, so I'm not even sure it's working right.  It does display the
JACK buffer size, which was useful. It is not in ``nixpkgs`` but I've created a
`Nix derivation to compile it from source
<https://github.com/mcdonc/.nixconfig/blob/master/pkgs/xruncounter.nix>`_.

I've disused ``musnix.realtime.enable`` because not all software that works on
non-realtime kernels will work on realtime kernels, and I use the same system
for general purpose tasks.  But I have set up ``musnix.rtcirq``, which I've
found works both with and without a realtime kernel.  It apparently can help
the system keep the right hardware active at the right times such that latency
is reduced and buffers are filled at the right times to keep the system audio
bucket brigade happy.

Making sure I've got the system configured to the satisfaction of ``rtcqs``,
running ``xruncounter`` and setting up ``musnix.rtcirq`` even without a
realtime kernel were done to reduce the chance of xruns, but frankly I haven't
seen any, so I can't really tell you if they've had an effect for good or bad.

To try to directly reduce audio monitoring latency:

- I've changed PipeWire's default, min, max, and JACK quantum settings.

- I've enabled and used wireplumber to do some special configuration of the
  ALSA settings for my audio interface.  In order to do so, I've measured by
  sound card's internal latency.

I think I have just about the lowest recording monitoring latency I'm gonna get
on this system.  It's not as immediate as my audio device's hardware
monitoring, but if I didn't have the hardware monitoring to compare it to, I
would believe it was realtime.  It's just a hair off.

To put the nail in the coffin of my Hackintosh, I've set up yabridge which
allowed me to get Arturia Collection and EZDrummer running.  Then, I overrode
the LXVST path to pick up changes made by yabridge.  Both have some weird
graphical glitches, but they work.

