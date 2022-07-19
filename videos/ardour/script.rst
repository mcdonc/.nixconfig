NixOS 33: Getting Ardour Audio Inputs Working on NixOS 22.05
============================================================

- Companion to video at ...
  
- See the other videos in this series by visiting the playlist at
  https://www.youtube.com/playlist?list=PLa01scHy0YEmg8trm421aYq4OtPD8u1SN

Video Script
------------

- I had a lot of trouble getting Ardour to record audio from any device under
  NixOS 22.05.

- I have not tried any older version of NixOS, nor have I tried unstable, so
  this may be a purely "point-in-time" issue.

- Things that I knew I had to do from experience on other systems:

  - Set ``security.pam.loginLimits = [ ... ]``.

  - Add myself to the ``audio`` group.

  - And other various more optional system hacks (show).

- The problems:

  - Ardour 6.9 would not work to record any audio in any mode: ALSA, PulseAudio or
    JACK.

  - Likely due to the above, Ardour 6.9 had problems quitting when in JACK mode.

- I had never experienced any of these problems under Ubuntu or Manjaro.

- Things I tried that didn't work:

  - Upgrading Ardour to a recent upstream master commit.  Same problems.

  - Downgrading Ardour to 6.8.  Same problems.

  - Downgrading Ardour to 6.7.  JACK didn't work at all, neither other mode
    worked either

  - Setting ``pipewire.package = pipewireFull;``

  - Adding ``boot.kernelModules = [ "snd-seq" "snd-rawmidi" ];``

- Things I didn't try that might have worked (but were too costly):

  - Disabling PulseAudio entirely.

- What worked:

  - Switching to Pipewire.

- ¯\_(ツ)_/¯

- No idea how stable the system will be with pipewire instead of PA/JACK, but
  I guess I'll find out.
  
