NixOS 47: Packaging Gotchas
===========================

- Companion to video at

- This script is available in a link in the video description.

- See the other videos in this series by visiting the playlist at
  https://www.youtube.com/playlist?list=PLa01scHy0YEmg8trm421aYq4OtPD8u1SN

Script
=======

When you package software for Nix, there are a few gotchas that you really must
be aware of to save your sanity.

The ``sha256`` / ``hash`` Argument to a Fetcher is a Cache Key
--------------------------------------------------------------

- Example we'll use to create a derivation of GNU hello:
  https://github.com/ritza-co/simple-hello-world-demo

- ``hello.nix``::

    { pkgs }:
    let
      version = "2.12";
      hello = pkgs.fetchFromGitHub {
        owner = "ritza-co";
        repo = "simple-hello-world-demo";
        rev = "v${version}";
        sha256 = "sha256-4GQeKLIxoWfYiOraJub5RsHNVQBr2H+3bfPP22PegdU=";
      };
    in
    pkgs.stdenv.mkDerivation  {
      pname = "hello";
      version = version;
      src = hello;
    }

- Note that there is exactly one tag in the repo, ``v2.12``.  There is no
  ``v2.11`` tag.

- Change version to ``2.11``, rerun.

- W. T. F.

- Doesn't refetch after you change version, URL, owner, etc.  You *must* change
  the hash.

- Note that it doesn't matter what the fetcher is: ``fetchFromGitHub``,
  ``fetchgit``, ``fetchurl``, etc.

- To diagnose and fix, one-by-one, replace existing SHA hashes with the empty
  string or ``lib.fakeSha256``.

- Really amps up distrust of Nix while you're building packages.

- Flailings:

  - https://discourse.nixos.org/t/force-full-redownload-and-rebuild-with-nix-build/18541

  - https://github.com/NixOS/nix/issues/3369

  - https://github.com/NixOS/nix/issues/2970
  
- No clear provided solution other than being very careful about hashes.

Why is Weird Shit Happening?
----------------------------

- Fetchers use ~/.cache/nix subdirs as caches

- https://github.com/NixOS/nix/issues/3271
  
- https://github.com/NixOS/nix/issues/2301
    
