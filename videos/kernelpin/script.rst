NixOS 35: Pinning The Kernel Version
====================================

- Companion to video at https://www.youtube.com/watch?v=CbgML-eifMM

- See the other videos in this series by visiting the playlist at
  https://www.youtube.com/playlist?list=PLa01scHy0YEmg8trm421aYq4OtPD8u1SN

Video Script
------------

- I use a custom kernel for a single dumb reason: I need a dumb two-line patch
  to it in order to make one of my dumb audio devices work.

- In a previous video, I suggested that the following configuration would pin
  the kernel, such that I could use Cachix (http://cachix.org) to avoid needing
  to rebuild the custom patched kernel on multiple systems.  I have several
  systems which are basically identical to each other, and I want them all to
  be able to use this audio device.::

    # enable the Roland RC-505 as an ALSA device

    boot.kernelPackages = pkgs.linuxPackages_5_15;

    boot.kernelPatches = [{
      name = "roland-rc505";
      patch = ./roland.patch;
    }];

- But, in reality, at least if you ever issue a ``nixos-rebuild switch
  --upgrade`` command, ``boot.kernelPackages = ...`` isn't a specific enough
  pin to avoid kernel rebuilds at upgrade time, because, over time, the thing
  referred to as ``pkgs.linuxPackages_5_15`` will refer to 5.15.48, 5.15.55,
  5.15.58, etc.

- Instead we must do this horrorshow::

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

    # patch the kernel
    boot.kernelPatches = [{
      name = "roland-rc505";
      patch = ./roland.patch;
    }];

- I cribbed this from the kernel page on the NixOS Wiki but it was for a 4.X
  kernel, so I just replaced the 4s with 5s and it worked.  The sha will of
  course be different if you don't use 5.15.55.
    
- Note that even *this* isn't enough to not see the kernel rebuild from time to
  time, for reasons I haven't quite pinned down (no pun intended).  I suspect
  it's because NVIDIA drivers get updated in the ``nixpkgs`` package, and when
  they do, because they aren't in-tree, its gotta start from scratch?  I dont
  fucking know.  In any case, in order to never see the kernel rebuild, I'll
  need to track those things down and pin *them*.
