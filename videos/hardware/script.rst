NixOS 21: Specify/Contribute New Hardware in ``nixos-hardware`` (aka "How Do Channel Imports Work")
===================================================================================================

- Companion to video at https://youtu.be/nqAdvgweq2k

- See the other videos in this series by visiting the playlist at
  https://www.youtube.com/playlist?list=PLa01scHy0YEmg8trm421aYq4OtPD8u1SN

Video Script
------------

- Aka "how do Nix channel imports work".
 
- https://github.com/NixOS/nixos-hardware

- To just use it, we can add it as a channel::

   sudo nix-channel --add https://github.com/NixOS/nixos-hardware/archive/master.tar.gz nixos-hardware
   sudo nix-channel --update

- Then import from it within your Nix configuration, ala
  https://github.com/mcdonc/.nixconfig/blob/master/thinknix51/hardware-configuration.nix

- ``lenovo/thinkpad/p53`` exists in ``nixos-hardware``, but no ``p51``, which
  is the Thinkpad model I'm using.  They are almost the same machine, so I
  could just pretend, and specify a p53 import.  This would actually work
  today.  But *almost* and *exactly* are worlds apart, and changes may happen
  upstream that are incompatible with p51.  This is why my
  hardware-configuration doesn't use it.

- Wouldn't it be convenient if ``nixos-hardware`` had my exact model so I
  didn't need to copy some of the code that already exists there in order to
  protect me from upstream changes?

- One way to do this: I could just check the code out and change it, and use
  the checked out code via a path import instead of a channel import::

    git clone git@github.com:NixOS/nixos-hardware.git

- Hack, hack.

- Upsides: easy to change.  Negotiate with no one.  Easy to check in to our own
  repository.

- Downsides: I don't get the benefit of any other eyeballs.  I can't easily
  share it between systems without checking it in to a repository I own.  These
  features negate some of the usefulness of having a shared nixos-hardware
  repository in the first place.

- If I want to be able to access the new configuration more cleanly, apply
  upstream fixes more easily, or submit a pull request so I don't even need to
  maintain my own copy of the code, the first step is to fork the repo using
  the Git web UI.

- Check out our fork::

    git clone git@github.com:mcdonc/nixos-hardware.git  

- The *second* step is to create a branch in the fork that has a name that
  represents what we intend to do::

    cd nixos-hardware
    git checkout -b pseries-additions

  This isn't required for bare functionality, but is often good practice if you
  intend to submit a pull request in the future (depends on the persnicketiness
  of upstream maintainers).

- Hack, hack, commit, push::

    git push -u origin pseries-additions

- After we've pushed, we can replace our path import with a channel import that
  points at an archive tarball that is generated automatically by GitHub for
  every branch and tag in our repository::

    sudo nix-channel --add https://github.com/mcdonc/nixos-hardware/archive/pseries-additions.tar.gz nixos-hardware-fork

  Note that the URL is different than our clone URL but it's the same code.

- Then we replace our custom configuration code with code from the channel.

- Upsides: code is accessible via a channel, so you needn't check
  nixos-hardware code into your own configuration repository.  Useful for
  multi-machine setups.  Code can be more easily submitted for review upstream.

- Downside: to move through time, I seemingly have to continually create tags
  and change the fork channel URL based on a new tag. If I just push something
  into the branch, ``nix-channel --update`` doesn't find anything new on the
  second run, so it's likely that the archive it downloaded hasn't changed.

- The current GitHub ``nixos-hardware`` channel instructions just tell you to
  point at the master archive, so maybe there's a way to invalidate the GitHub
  archive cache; I don't know.
  
- I won't be submitting a pull request just yet, because I'm not totally solid
  on how to test the code for this configuration to meet the standards of the
  maintainers (shitty PRs are often worse than no PRs).
