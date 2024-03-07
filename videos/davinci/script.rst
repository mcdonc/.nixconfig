================================
DaVinci Resolve on Linux (NixOS)
================================

The state of open source NLE video editing on Linux is good if your needs are
very basic.  Two reasonably good editors exist that I have a lot of experience
with: Kdenlive and Olive.  These both work fine.  However, Kdenlive's UI is
strange; it can also be crashy, and Olive is no longer maintained.  There are a
number of other contenders, but they all have one fatal flaw or another.

Of course, I knew about DaVinci Resolve, and I had even used it to produce one
video a year or two ago on Linux, but my needs are incredibly basic, and its
quirks around import and export turned me off to it.  But then when I saw the
audio transcription / text editing feature of Resolve Studio 18.6 (the paid
version), I knew I must re-investigate the quirks, and, if possible, circumvent
them, and maybe possess it.

There has seemingly always been a barely-traversable minefield of gotchas
around using DaVinci Resolve on Linux.  The minefield itself truly a work of
art.  It has that
"you-Linux-trash-are-not-our-target-market-so-here-why-don't-you-spend-an-entire-day-figuring-out-whether-it-will-work-at-all-for-you-oh-and-fuck-you-too."
After you understand the minefield, depending on your level of submissiveness,
you will find that it may or may not be suitable for you.

By the way, it doesn't matter that you want to pay money for it.  You are a
Linux user, and therefore you don't really matter, no matter how many thousands
of dollars you might performatively wave around.  Real video editors use a Mac,
and the second-class ones use Windows.  We don't even know what class you're
in, you fucking weirdo.  You should be glad it even exists.

Which is ironic, because I believe it was originally a Linux-only product when
it cost thousands and thousands of dollars.  But now it's only $300 for a
forever-license (all future versions are free), so I guess some cost-cutting
concessions had to be made.  Linux feature parity was one.

Apparently I'm the bottom in this relationship, because I ended up buying
Resolve Studio.  Most of what I mention below relates to the Studio (paid)
version, although I discuss the differences between Resolve and Resolve studio
when it comes to feature parity as I've encountered them.

The Minefield of Gotchas
------------------------

I should make some sort of chart for this, but I'm far too lazy.

What doesn't work on Linux or Windows (Macs N/A).

- Any system without discrete graphics.  I'm not sure they even consider Intel
  ARC "discrete".  It requires AMD or Nvidia as far as I can tell, and really,
  in practice, Nvidia.  And really, a very beefy Nvidia card, not some wimpy
  one, more on this in a bit.

What doesn't work on Linux or Windows in the free version:

- H.264 video decoding

- H.265 video decoding

- Audio transcription and some other AI features
  
What doesn't work on Linux in the free or paid version:

- AAC audio decoding (patent claims)
     
- AAC audio encoding (patent claims)

- Accelerated encoding (and decoding?) on AMD GPUs.

If you're producing content mostly for YouTube, using Resolve on Linux is less
convenient than using it on a PC or a Mac due to the non-support of AAC audio.
You almost always have to transcode your content for import usually because
most consumer cameras and phones produce H.264 video with AAC audio in an MP4
container, and neither Resolve nor Resolve Studio can cope with it.

If you produce footage with OBS, it can be convinced to use a Matroska (mkv)
container instead of MP4, but it can only encode to AAC or Opus (ogg) audio.
Resolve can't use AAC or Opus, so, like camera footage, transcode it you must.

If you use AMD on Linux, you have to use the proprietary ``amdgpu-pro`` drivers
for it to run at all, which are apparently crap for gaming.  As far as I can
tell, must have an Nvidia card for any accelerated video. This may even
translate to playback monitoring, not sure; they seem to rely on CUDA heavily
for many features.  I don't have an AMD card to use to confirm this.

Since the Intel Macs have always been AMD, why is there no AMD
encoding/decoding acceleration on Windows or Linux?  Who knows.

So you should have an Nvidia card in practice.  What's that you say?  You have
a GTX1030?  Well fuck you, you poor, that only has 2GB of RAM on it.  Resolve
won't even get out of bed unless you have 4GB of RAM omn your GPU, and that's
the *very minimum*, like, scraping the barrel minimum.  That means you need at
least a GTX 1050ti, or a Quadro P1000.  No, fuck you, it won't fall back to
software for this stuff, your 64G of system RAM is useless.

Great now you have a card that lets you actually enter the Resolve UI.  But
with only 4GB of GPU RAM, it will complain at you incessantly and refuse to
complete most minimally complex previewing, AI, and rendering tasks without
workarounds and magical incantations, and maybe not even then.  You really
should have *at least* 8GB of GPU RAM, and that's only for very basic video
editing with a single track on the timeline at 1080p without any effects.  If
you want effects and you want to edit in 4K, fuck you, buy a current-gen dollar
video card with 24GB of RAM for six, seven, eight hundred or a thousand
dollars.

Hey by the way, Resolve is officially only supported on Linux via CentOS.  Even
today.  Yes, you heard that right.  The OS by Red Hat that is no longer is
released.  Unofficially, Blackmagic supports it on Rocky Linux, at least via
its forums.  There are probably unofficial packagings of it for all the popular
Linux distros.  Some poor soul has spent a lot of time on to containerize it;
it has come to that: https://github.com/fat-tire/resolve

However, both DaVinci Resolve (free) and DaVinci Resolve Studio (paid) are
packaged for NixOS thanks to the hard work of jshmpbll and orivej
https://github.com/NixOS/nixpkgs/blob/master/pkgs/applications/video/davinci-resolve/default.nix
.  Thanks to their hard work, if you use NixOS, you needn't think about any of
that, you just add ``davinci-resolve`` or ``davinci-resolve-studio`` to your
system packages, and it works.  The current version packaged for NixOS is
18.6.5.

I told you it was complicated.

On the Other Side of the Minefield
----------------------------------

I use the Studio version of Resolve, so I transcode my input footage to H.264
with PCM audio into a Matroska (mkv) container.  Resolve Studio is fine with
that.  I do this because I have an Nvidia card (a Quadro P1000) that does
hardware-accelerated H.264 encoding via NVENC, and this combination of video
and audio encoders produces a reasonably small transcode reasonably quickly::

  ffmpeg -i input.mp4 -c:v h264_nvenc -c:a pcm_s16le output.mkv

If I were using the free version, I would not be able to use H.264 as an input
video format, so the previous command would not produce something that Resolve
could import. I would instead want to use AV1 video.  It's much slower, but
Resolve can import the result::

  ffmpeg -i input.mp4 -c:v libsvtav1 -preset 10 -crf 35 -c:a pcm_s16le output.mkv

I would also want to use AV1 video if I didn't have hardware-accelerated H.264
encoding.  The ``libsvtav1`` encoder is, surprisingly, faster than the software
H.264 encoder, at least for the kinds of footage I'm transcoding.

Resolve badly wants to be used in a dual monitor setup.  It wants to consume an
entire monitor for itself.  It always starts at full-screen size.  And it wants
that monitor to be at least 4K resolution.  If it's not, bizarre shit happens,
like at 1080p, where the menus are cut off at both sides and some UI elements
are simply unclickable because they're off the screen.

Which is fucking ironic on Linux at least, because when it's at 4K, it's
utterly unreadable.  You must preferences / user / UI settings / UI display
scale and change it to 150K.

OK, so you have a 4K monitor.  And you've figured out how to scale the UI so
it's readable.  But you only have one monitor.  You'll want to *resize* the
Resolve window.  Well fuck you.  Figure out that you need to drag it out of
full-window mode by pressing the Super key and left dragging.  And figure out
that after you snap it out of its fullscreen mode, you still need to use the
super key while you try drag its window around.  And fuck you, the UI may or
may not be usable due to inconsistent scaling.  I mean basically fuck you.

I render to H.264/mp3 in a Matroska container because all my systems can
accelerate H.264 rendering.  YouTube is fine with this, I have no need to
transcode it before uploading.  YMMV, my needs are *very* basic (I don't even
use stereo sound).

The features I love:

- Audio normalization for youtube on render / audio page 

- Audio transcription and text editing.

  Audio transcription on a 4GB Quadro P1000 GPU often runs out of GPU memory.
  For me, changing my desktop resolution to 1080p instead of 4K gives it enough
  headroom to finish.  You can then change back to 4K.  I've also *think* I've
  seen it get enough headroom to finish by changing the GPU processing mode to
  OpenCL (although it goes much, much slower), but it might have been a fluke.



  
