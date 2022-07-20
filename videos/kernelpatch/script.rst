NixOS 30: Patching the Kernel (aka Making the Roland RC-505 Looper Work)
========================================================================

- Companion to video at https://youtu.be/eX_s2lLHRgM

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

- https://github.com/mcdonc/.nixconfig/blob/master/videos/kernelpatch/roland.patch

- How do we convince NixOS to apply this patch?

- The NixOS kernel page is cagey about it (show it).

- But as I found on Reddit (show it), it's stupid easy::

    # enable the Roland RC-505 as an ALSA device

    # pin the kernel so we don't need to keep building it
    boot.kernelPackages = pkgs.linuxPackagesFor (pkgs.linux_5_15.override {
      argsOverride = rec {
        src = pkgs.fetchurl {
              url = "mirror://kernel/linux/kernel/v5.x/linux-${version}.tar.xz";
              sha256 = "sha256-Hva9UItsOvO+8tWzN+RHclTbooTHnjKao4+XY647/cw=";
        };
        version = "5.15.55";
        modDirVersion = "5.15.55";
        };
    });

    # this pin is not specific enough
    # boot.kernelPackages = pkgs.linuxPackages_5_15;

    # patch the kernel
    boot.kernelPatches = [{
      name = "roland-rc505";
      patch = ./roland.patch;
    }];

- We pin the kernel version so our patch can be applied cleanly.  Then we
  specify the patch and ``nixos-rebuild`` and reboot.

- Bob, uncle.

