NixOS 29: Using Older (Working) Revisions of Software When the Latest Doesn't Work
==================================================================================

- Companion to video at ...

- See the other videos in this series by visiting the playlist at
  https://www.youtube.com/playlist?list=PLa01scHy0YEmg8trm421aYq4OtPD8u1SN

Video Script
------------

- It's easy to forget how mind-blowing some of the features of Nix are.  You
  ready to have your skull caved in?

- Remember when the last time you upgraded your shit on your last OS and
  something that seemed unrelated broke?

- Might not even be because of a version bump in the thing that broke; might
  have been a change to one of its dependencies.  Or one of its dependencies'
  dependencies.

- Nix doesn't work like that.  A Nix derivation depends on other specific
  derivations.  Each derivation has a hash.  When each derivation builds, the
  hashes of its inputs are used to produce its hash.  The rootmost derivation
  in a tree of derivations has a hash, and that is prepended to its junk when
  its put into the store.

- What this means is that each derivation doesn't just depend on specific
  software versions of each other derivation.  It means that each derivation
  depends on specific *hash* versions of each other derivation.

- For example, there may be a hundred different hashes representing ``bind``
  version 9.18.3.  Each version represents a slightly different build of that
  specific version of ``bind``. At each build, even though the software has the
  same revision, the hash of one of its dependencies (or one of its
  dependencies' dependencies etc) was different at some specific point in time.

- These points in time are captured in changes to the Nixpkgs repository.  It
  is totally possible to reverse engineer exactly which commit to the Nixpkgs
  repository resulted in a specific derivation having some specific hash.

- Nixpkgs -- the GitHub repository -- is just a big honking set of how to build
  software from source.

- The only reason that you don't see (like old-school Gentoo) everything
  building from scratch when you issue a nix-rebuild is that Nix first checks a
  *cache* to see if a derivation (and all of the derivations upon which it
  depends) are available.

- 9.9-times-out-of-10 the answer is yes, at least for amd64.

- The ``hydra`` build system is the primary method by which this cache is populated.
  https://hydra.nixos.org

- When a change is made to the ``nixpkgs`` GitHub repository (and probably
  other repositories), the Hydra build system attempts to rebuild the
  derivations that were impacted by the change.  If it must build new
  derivations, it does, and -- if the builds succeed -- those derivations are
  jammed into the cache.

- Thus, throughout time, each time a successful build happens in Hydra, that
  build is made available to the world.

- A corollary exists: if something has *ever* built in Nixpkgs, chances are you
  can use it because it's probably still in the cache at cache.nixos.org.

- Fucking mindbending.

- Let's take a look at ``bind``.
  https://search.nixos.org/packages?channel=22.05&show=bind&from=0&size=50&sort=relevance&type=packages&query=bind and its x86_64-linux build.

- Click help.

- ``nix-env -i /nix/store/b0nknrw1bbxkgi4ybc3r05jwzzifqbps-bind-9.18.3-dev --option binary-caches https://cache.nixos.org``

- Let's try ``olive-editor``because I know the current build no-worky.

- https://hydra.nixos.org/job/nixos/release-22.05/nixpkgs.olive-editor.x86_64-linux

- "Latest successful build" link is busted, likely because Olive has been
  broken for a long time and Hyrda probably had to garbage collect the history
  of better days.

- But I happened to catch it at a point in the past when it hadnt yet purged
  that history, so I know the "Help" link told me to do this::

    nix-env -i /nix/store/4nq5wfa01vq6x00q8k777qhf47bp2wd4-olive-editor-0.1.2 --option binary-caches https://cache.nixos.org

- Usually you specify a "package name" to ``nix-env -i`` e.g.::

    nix-env -i olive-editor

- But when the value you pass to ``nix-env -i`` is a *store path*, it behaves a
  little differently.  It attempts to look up the derivation in the cache and
  *realize* it.  See the discussion of "realisation" in the nix-store
  documentation.  Basically, realization means that it just tries to download
  that exact derivation, and all the derivations upon which that derivation
  depends, rather than even attempting to build the package from source.
  
- But ``nix-env`` sucks.  Imperative configuration sucks.  It sucks for all the
  reasons you hated your old system and you started to use NixOS instead in the
  first place, so you shouldn't bother with ``nix-env``.

- Instead::

    environment.systemPackages = with pkgs; [
      # ...
      /nix/store/4nq5wfa01vq6x00q8k777qhf47bp2wd4-olive-editor-0.1.2
      # ...
      ];
    
- That shit works.  Unreal.  Your system went back in time three months -- only
  for *that one piece of software*, everything else is untouched, everything
  else still works.  *And* you spelled it in such a way that you can *repeat
  it* just by running a rebuild.


  
