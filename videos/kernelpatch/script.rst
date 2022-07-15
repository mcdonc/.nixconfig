NixOS 30: Patching the Kernel
=============================

- Companion to video at ...

- See the other videos in this series by visiting the playlist at
  https://www.youtube.com/playlist?list=PLa01scHy0YEmg8trm421aYq4OtPD8u1SN

Video Script
------------

- I got a fever.  And the only remedy is more looping.

- BOSS/Roland RC-505 (view pic).

- It is a looper.  You sit in front of it like an asshole.  It can play a beat.
  Then, along with the beat, you can record yourself singing or playing some
  number of instruments.  But it has four channels, so once you get done
  recording yourself on channel 1, you can record yourself playing/singing
  along with yourself of the past on the channel 2.  It also has effects.

- It's stupid cool in anyone's hands but mine.  (show vid)

- But, out of the box, it isn't recognized as an ALSA device in Linux.

- Fixing it is just a matter of adding it to some quirks table inside the kernel.
  (show patch).

- How do we convince NixOS to apply this patch?

- The NixOS kernel page is cagey about it (show it).

- But as I found on Reddit (show it), it's stupid easy::

    # enable the Roland RC-505 as an ALSA device
    boot.kernelPackages = pkgs.linuxPackages_5_15;
    boot.kernelPatches = [{
      name = "roland-rc505";
      patch = ./roland.patch;
    }];

- We pin the kernel version so our patch can be applied cleanly.  Then we
  specify the patch and ``nixos-rebuild`` and reboot.

- Bob, uncle.

