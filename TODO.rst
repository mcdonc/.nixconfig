- Why doesn't ``nix-channel --update`` detect changes made to branches related
  to "releases" generated via GitHub's ``/archive/branchname.tar.gz``
  convention?  E.g. if I add and update the channel
  https://github.com/mcdonc/nixos-hardware/archive/pseries-additions.tar.gz ,
  then push a commit to
  https://github.com/mcdonc/nixos-hardware/tree/pseries-additions , if I
  ``--update`` again, it doesn't build a new derivation with the changes pushed
  to the branch.  Note that *GitHub* seems to be doing the right thing.
  Downloading the release by hand gives me a tarball with the changes.

- I currently have to install ``olive-editor`` (video editor) by hand because
  the build is broken (https://hydra.nixos.org/build/173379959).  I currently
  use ``nix-env`` to get the last known working build::

    nix-env -i /nix/store/4nq5wfa01vq6x00q8k777qhf47bp2wd4-olive-editor-0.1.2 --option binary-caches https://cache.nixos.org

  Is there a way to do this declaratively in my configuration instead?
  
