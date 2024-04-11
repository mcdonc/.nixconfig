====================================================================================
NixOS 85: NixOS as a Music Production System, Part 2 (Optimizing Monitoring Latency)
====================================================================================

Companion to video at

This text script available via link in the video description.

See the other videos in this series by visiting the playlist at
https://www.youtube.com/playlist?list=PLa01scHy0YEmg8trm421aYq4OtPD8u1SN

Script
------

In my video entitled `#83 NixOS as a Music Production System
<https://www.youtube.com/watch?v=_M_vSwGGVzY>`_, I got PipeWire and Musnix set
up for generic low latency recording and monitoring, and I got Ardour and
Audacity working with some plugins.  This is the second video in this series,
where we'll dive deeper into pro audio on NixOS by further optimizing
monitoring latency and trying to ensure that we get the fewest number of
"xruns" (errors that happen when our audio hardware can't feed our software
fast enough).

I'll be using rtcqs, changing Musnix rtirq config, disusing the low-latency
kernel, using a new Musnix feature for rtcqs, measuring sound card hardware
latency, and adding programs called wireplumber, and xruncounter.

I'm going to use a NixOS flake to configure our system.  If you haven't yet
switched over to flakes, apologies, but you might want to check out one or both
of my videos entitled `NixOS 63: Install NixOS 23.11 and Use Flakes Out Of the
Box <https://youtu.be/hoB0pHZ0fpI>`_ or `NixOS 40: Converting an Existing NixOS
Configuration To Flakes <https://youtu.be/Hox4wByw5pY>`_.

I'm going to start in a place that is close to where I left off in my last
video in the series.  In that video, I used a virtual machine, so I couldn't
really demonstrate what performance and monitoring latency was like in the real
world.  But in this video, I'll be configuring NixOS on real hardware, a Dell
Optiplex 3070 micro (small form factor) desktop.  It's a four-year-old six-core
2.2Ghz Intel i5-9500T with 32GB of RAM.  It gets scores of about 1300
single-core and 4600 multi-core in Geekbench 6.  You can get one on eBay today
for about $130.

Stuff
-----

A new-ish Musnix feature (new since my last video) provides access to a script
named `rtcqs <https://codeberg.org/rtcqs/rtcqs>`_ .  This script analyzes your
system configuration and offers suggestions about changes that could be made to
reduce audio latency.

.. code-block:: nix

   musnix.rtcqs.enable = true;

I've set up a program named `xruncounter
<https://github.com/Gimmeapill/xruncounter>`_ to try to generate xruns.  xruns
happen when the operating system cannot supply the audio subsystem with data
fast enough.  It is not in ``nixpkgs`` but I've created a `Nix derivation to
compile it from source
<https://github.com/mcdonc/.nixconfig/blob/master/pkgs/xruncounter.nix>`_.

In my first video in this series, I used a realtime kernel.  But since then
I've disused ``musnix.realtime.enable`` because not all software that works on
non-realtime kernels will work on realtime kernels, and I use the same system
for general purpose tasks.  But I have set up ``musnix.rtirq``, which I've
found works both with and without a realtime kernel.  It apparently can help
the system keep the right hardware active at the right times such that latency
is reduced and buffers are filled at the right times to keep the system audio
bucket brigade happy.

Making sure I've got the system configured to the satisfaction of ``rtcqs``,
running ``xruncounter`` and setting up ``musnix.rtirq`` even without a realtime
kernel were done to reduce the chance of xruns, but there are so many knobs to
turn (some that we haven't talked about yet, even) that might effect this that
I can't really tell you if they've had an effect for good or bad at the moment.
I think I'm going to have to use the thing for a while longer to see which
knobs are best turned and which are left best alone.

So we'll move on to realtime monitoring latency.  Human psychoacoustics are
such that two distinct but similar sounds cannot be reliably distinguished
apart if they are within somewhere between 10-20 milliseconds from each other.
The sound of our voice or our guitar pluck is picked up by our microphone or
guitar pickup, subsequently processed by our audio software, and then fed back
into our ears via our monitoring headphones, particularly when using audio
processing software like effects stacks.  We want the sound we make to get into
our mic or pickup, through our computer rig, processed by our software and
plugins and out of our headphones into our ears within this number of
milliseconds.  Otherwise, we will hear *both* the original sound and the
monitored sound phased slightly (or totally) out of sync, which will destroy
our ability to concentrate on the instrument that we are monitoring.  This
isn't an issue with straight up recording where we aren't listening back to the
processed input in realtime, it only is a problem when we want to monitor it
while we are actually making the noises.

To start, we need to do some fooling around with hardware settings.  In
particular, we need to determine the lowest possible settings we can use for
the ALSA "period size" and "period number" that purports to give us a roundtrip
latency for a test pattern sound (without any processing or effects) at least
below 20ms, and ideally below 10ms.  We can use the ``alsa_delay`` program to
do this.

Note that it's important that we don't have any ALSA configuration changes from
default while we do this; if we do, we will get misleading numbers.

Let's run ``alsa_delay``.  

- Set the hardware on your sound card to a sample rate of 48Khz and reset it.

- Connect a cable from each of your sound card outputs to each of your sound
  card inputs.  If you have more inputs than outputs, you'll need to pay
  attention in later steps to which inputs you've connected cables to.  I
  don't, so I haven't.

- Shut down all other sound software (Ardour, Audacity, etc, maybe even
  pipewire).  Otherwise the hardware device you're looking for might not
  show up in the next step.

- Run ``aplay -l`` to list all the sound devices attached to your system; note
  the card number (and optionally subdevice) of the sound card you want.

- Run ``nix-shell -p zita-alsa-pcmi``.  This will put the ``alsa_delay``
  program we will use to measure roundtrip audio latency on the PATH.

- Run ``alsa_delay hw:1 hw:1 48000 128 3 1 1`` Replace ``hw:1`` with your
  ALSA device number you gleaned from ``aplay -l``.  It goes
  ``hw:cardnum,device`` or just ``hw:cardnum`` if no subdevices.
  It will show output something like::

      968.800 frames     20.183 ms

- Reduce the "128" (the period size) and "3" (the period number) in-order,
  until finally ``alsa_delay`` reports that it can't open the ALSA device::

    $ alsa_delay hw:1 hw:1 48000 128 3 1 1
    $ alsa_delay hw:1 hw:1 48000 128 2 1 1
    $ alsa_delay hw:1 hw:1 48000 64  3 1 1
    $ alsa_delay hw:1 hw:1 48000 64  2 1 1
    $ alsa_delay hw:1 hw:1 48000 32  3 1 1
    $ alsa_delay hw:1 hw:1 48000 32  2 1 1

  I start getting weirdness (pops and clicks and error/warning output from
  alsa_delay) at "64/3"; past this point it's all either weirdness or "can't
  open ALSA device".  This means that the best I can really do is 128 for the
  period size and 2 for the period number, which equates to the lowest
  roundtrip latency that my hardware can handle at 14.5ms or so.

- I'll then use Ardour to try to figure out how much of that latency is due to
  the DACs in my sound card and computer hardware itself, as opposed to in the
  rest of the chain. This is known as "systemic latency".  Software can do some
  recording-time compensation for systemic latency (apprently most noticeable
  for punch-ins) if we set it properly.  Audio/MIDI setup, ALSA audio system,
  choose the right device, set the period size and number we found in the last
  step as "buffer size" (128) and "periods" (2), respectively, go to Advanced
  Settings -> Calibrate Audio and click "Measure".  Mine is 472 samples/9.833ms
  *roundtrip* latency, and *a systemic latency* of 344 samples/7.166ms.  We
  care about the number of systemic latency samples for the next step.

- Click "use results" and try to record to an audio track.  Make sure it works
  and there is no audio artifacting.  If there is artifacting, inside Ardour,
  reconfigure Ardour's ALSA settings and re-record, working your way back up
  the pairings of period size and number from the ``alsa_delay`` step above
  until there isn't.  The settings that produce no artifacting are your actual
  lowest settings for period size and number.

Now that I've figured out the optimum period size, period number, and systemic
latency for my audio card, I'll enable and use ``wireplumber`` to do automatic
configuration of PipeWire with these settings when it starts.  Wireplumber is
what notices audio devices as they're added to the system, and when it notices
ours, we'd like it to remember that, for our audio card, it should interface at
a low level with these settings.

We will create a file in ``/etc/wireplumber/main.lua.d/52-usb-ua25-config.lua``
to do this.  When wireplumber starts, it will run the code in this file to
configure PipeWire's JACK and native APIs to use these particular ALSA settings
when used against this card.::

     environment.etc."wireplumber/main.lua.d/52-usb-ua25-config.lua" = {
       text = ''
         rule = {
           matches = {
             {
               -- Matches all sources.
               { "node.name", "matches", "alsa_input.usb-Roland_EDIROL_UA-25-00.*" },
             },
             {
               -- Matches all sinks.
               { "node.name", "matches", "alsa_output.usb-Roland_EDIROL_UA-25-00.*" },
             },
           },
           apply_properties = {
             -- latency.internal.rate is same as ProcessLatency
             ["latency.internal.rate"] = 344,
             -- see Robin Gareus' second post after https://discourse.ardour.org/t/how-does-pipewire-perform-with-ardour/107381/12
             ["api.alsa.period-size"]   = 64,
             ["api.alsa.period-num"]   = 2,
             ["api.alsa.disable-batch"]   = true,
           },
         }

         table.insert(alsa_monitor.rules, rule)
       '';
     };

You will need to change the ``node.name`` for both inputs and outputs to match
your sound card.  You'll have to consult the Wireplumber docs for how to find
the sound card ``alsa_input`` and ``alsa_output`` names it needs in the format
it wants.  I got lucky; someone else had already figured them out for my sound
card.  In any case, I plug numbers into this snippet.
``latency.internal.rate`` is my systemic latency of 344,
``api.alsa.period-size`` is 64 found via ``alsa_delay`` and
``api.alsa.period-num`` is 2, also found via ``alsa_delay``.  I am also messing
with ``api.alsa.disable-batch``, which does something I don't understand yet,
caveat emptor.

Note again that these values are used by *PipeWire*, they are not respected by
any application which talks to ALSA directly.

Now we need to configure JACK settings related to latency.  Note from here on
  in that every time we make a change to ``92-low-latency.conf`` or
  ``52-usb-ua25-config.lua``, we need to restart pipewire and wireplumber::

   systemctl --user restart pipewire wireplumber

- Run ``nix-shell -p jack-example-tools`` to put ``jack_iodelay`` on the path.

- Connect cables on your sound card from input to output just like in the prior
  ALSA-configuration stuff.

- run ``jack_iodelay`` with no arguments.

- Run QJackCtl and use the GUI to connect jack_delay's "in" port to an
  appropriate "capture" port on your sound card.  Connect jack_delay's "out"
  port to an appropriate "playback" on your sound card.  Mess with your sound
  card's input and output volume knobs like a ZX Spectrum tape volume. When it
  works, you will see something like this on the ``jack_iodelay`` console::

    328.807 frames      6.850 ms total roundtrip latency
	extra loopback latency: 4294966808 frames
	use 2147483404 for the backend arguments -I and -O

"Extra loopback latency" is the latency measured by ``jack_iodelay`` for
"systemic latency."  We are seeing an absurd number for "extra loopback
latency" measurement because we set ``latency.internal.rate`` (systemic
latency) via ``52-usb-ua25-config.lua`` and the computation of device latency
by ``jack_iodelay`` isn't taking that into account, and appears to be
overflowing.  If we disable the wireplumber ``latency.internal.rate`` option
and restart pipewire and wireplumber, we see a more reasonable number.  But
strangely, not the *same* number that we measured via Ardour.  We get 200
instead of 344.::

     328.800 frames      6.850 ms total roundtrip latency
        extra loopback latency: 200 frames
        use 100 for the backend arguments -I and -O

If your numbers are also different, I'm not sure what the right thing to do is.
I've gleaned most of what I've related so far from forum posts of dubious
provenance, and lots of interactive testing.  But I'll tell you how I've
decided to arbitrarily split the difference.  Since JACK is how I'm going to
record, I want to please ``jack_iodelay``.  How I've done that is to set
``latency.internal.rate`` in the lua file such that the "extra loopback
latency" reported by ``jack_iodelay`` becomes 0.  In my case, that meant
ignoring the "344" reported by Ardour's ALSA calibration, and using *half* of
the "extra loopback latency" number reported by ``jack_iodelay`` instead.  So I
changed ``latency.internal.rate`` from 344 to 100.  Now when I restart pipewire
and wireplumber and rerun the ``jack_iodelay`` latency test, I get 0 extra
loopback latency, which looks like this::

   328.810 frames      6.850 ms total roundtrip latency
        extra loopback latency: 0 frames
        use 0 for the backend arguments -I and -O

I have no idea whether this is optimum, but frankly I cannot tell the
difference when using one vs. the other.  This is getting into undetectable
territory.

Lastly, I've changed PipeWire's default, min, max, and JACK quantum settings to
match my sound card's "period" (64)::
  
    environment.etc."pipewire/pipewire.conf.d/92-low-latency.conf" = {
      text = ''
        context.properties = {
          default.clock.quantum = 64
          default.clock.min-quantum = 64
          default.clock.max-quantum = 64
        }
        jack.properties = {
          node.quantum = 64/48000
        }
      '';
    };

I could not detect that this had much effect when listening in, to be honest,
but the meters in the JACK software I was using (Ardour) dipped to 1.3ms vs
20ms as a result (see the Audio/MIDI setup).  I think a quantum is largely
equivalent to a ALSA "period", so having them be the same by default seems
reasonable.  I think the more important of the two things there is
jack.properties' node.quantum which tells things connected to JACK what the
buffer size is.  It may be that as I add more devices or use different software
that I need to mess around with the min and max quantum, so that everything
sounds good together.  I'll have to find out.

But as a result of all this, I think I have just about the lowest recording
monitoring latency I'm gonna get on this system.  It's not as immediate as my
audio device's hardware monitoring, but if I didn't have the hardware
monitoring to compare it to, I would believe it was realtime.  It's just a hair
off.
