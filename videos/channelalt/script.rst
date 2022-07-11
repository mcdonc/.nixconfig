NixOS 27: An Alternative to Using Channels
==========================================

- Companion to video at https://youtu.be/cv3Cwgpx0G0

- See the other videos in this series by visiting the playlist at
  https://www.youtube.com/playlist?list=PLa01scHy0YEmg8trm421aYq4OtPD8u1SN

Video Script
------------

- Thanks to Domen Kožar for the tips.

- Channels are out-of-code pointers to repositories of NixOS configuration/code.

- Adding channels::
    
   sudo nix-channel --add https://github.com/nix-community/home-manager/archive/release-22.05.tar.gz home-manager
   sudo nix-channel --add https://github.com/NixOS/nixos-hardware/archive/master.tar.gz nixos-hardware
   sudo nix-channel --update

- Then, in code::

   imports = [
     <home-manager/nixos>
     <nixos-hardware/lenovo/thinkpad/p51>
   ];
    
- Problems with channels:

  - It is not obvious while reading the code exactly which set of code a
    channel represents because the codebase signifier (its URL) is maintained
    out of band of the code.

  - A build that uses channel imports might do wildly different things on two
    systems configured with different sets of code under the same channel name.

  - It is unclear how to force a channel to download a new version of the same
    set of code at the same URL.  ``nix-channel --update`` often does nothing
    when you think it should re-grab an updated copy of the repository.

- Many Nix old-timers seem to avoid using channels, for what I presume to be at
  least partially related to the above enumerated reasons.

- Note that a channel points at a URL that is usually just a tarball of a
  GitHub repository on a certain branch (or tag, or commit number).

- It is possible to get the same result using ``fetchTarball`` and non-channel
  imports in your code.

- Using ``fetchTarball`` instead of a channel ameliorates some of the problems
  with channels I enumerated.

  - The codebase signifier is alongside the other code, so you can figure out
    more easily what codeset it refers to.

  - You cannot configure two systems accidentally with two different code sets
    if you don't use channels (also a potential downside).

  - The TTL of tarballs seems more predictable: by default, it caches
    downloaded tarballs for an hour before it attempts to redownload.  This
    seems to be configurable by ``tarball-ttl`` in nix.conf.  This can be
    changed in your normal nix configuration::

        nix.settings = {
         tarball-ttl = 300; # seconds
        };

    Set it to zero to never use a cached copy.

- I forked the ``nixos-hardware`` repository to do some hacking.  Initially I
  used channels to specify that I wanted to use my fork::

     sudo nix-channel --add https://github.com/NixOS/nixos-hardware/mcdonc/archives/pseries-additions.tar.gz nixos-hardware-fork
     sudo nix-channel --update

- Then, in my code, I used the fork by specifying a channel import (a value in angle
  brackets within an imports command)::

    imports = [
     <nixos-hardware-fork/lenovo/thinkpad/p51>
    ];

- This worked fine, but I was iterating pretty hard, and updating my channels
  via ``nix-channel --update`` would not pick up my new commits for an
  unpredictable amount of time.

- So I resorted to reassigning the channel name to an alternate URL that
  represented a point in time after I made after a commit I wanted to test (a tag) via::

    git tag v2
    git push -u origin v2
    sudo nix-channel --remove nixos-hardware-fork
    sudo nix-channel --add https://github.com/NixOS/nixos-hardware/mcdonc/archives/v2.tar.gz

- Every. Commit.  I. Wanted. To Test.

- Eventually I gave that up and fell back to importing directly from a checkout
  I hade on the filesystem::
    
    imports = [
     /home/chrism/projects/nixos-hardware/lenovo/thinkpad/p51
    ];

- This mildly sucked because I wanted to test it on multiple machines and I had
  to maintain a checkout of the code in the same place on all of them.

- Domen suggested using ``fetchTarball`` instead::

    let
      hwfork = fetchTarball "https://github.com/mcdonc/nixos-hardware/archive/pseries-additions.tar.gz";
    in
    {
      imports = [
        (import "${hwfork}/lenovo/thinkpad/p52")
      ];
    # ...
    }

- Completely equivalent to a channel, except with less indirection, and cannot
  be used imperatively with ``nix-env`` (which I never use anyway).

- This solved every problem I had except I'm still a little unclear where the
  cached copies of the repository are stored and how they are garbage collected.

  
