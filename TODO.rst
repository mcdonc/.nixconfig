- Why doesn't ``nix-channel --update`` detect changes made to branches related
  to "releases" generated via GitHub's ``/archive/branchname.tar.gz``
  convention?  E.g. if I add and update the channel
  https://github.com/mcdonc/nixos-hardware/archive/pseries-additions.tar.gz ,
  then push a commit to
  https://github.com/mcdonc/nixos-hardware/tree/pseries-additions , if I
  ``--update`` again, it doesn't build a new derivation with the changes pushed
  to the branch.  Note that *GitHub* seems to be doing the right thing.
  Downloading the release by hand gives me a tarball with the changes.

  Using fetchTarball has a similar issue, although at least it's more obvious
  how to work around it.  fetchTarball claims to respect a setting named
  "tarball-ttl" from the Nix environment, and the code reads as if it would put
  the tarball into ~/.cache/tarballs (it doesn't) or /root/.cache/tarballs (it
  doesn't).  And, using it in a setup where you are invoking it from NixOS,
  unless it's something like ``nixos-rebuild -I tarball-ttl=1 ..`` (it doesn't
  seem to be), it's unclear how to set the ttl to make it redownload a tarball.
  Also, I don't want to redownload all tarballs, just that one, if possible.
