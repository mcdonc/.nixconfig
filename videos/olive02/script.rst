NixOS 37: Building Your Own Derivation from Upstream Sources
============================================================

- Companion to video at ...
  
- See the other videos in this series by visiting the playlist at
  https://www.youtube.com/playlist?list=PLa01scHy0YEmg8trm421aYq4OtPD8u1SN

Video Script
------------

- As I've mentioned a thousand times already in this series, I use the Olive
  video editor to edit these videos.  https://www.olivevideoeditor.org/

- It is an open source nonlinear video editor that sucks much, much less than
  most other open source video editors I've tried, and, to me, at least, much
  less than many commercial ones.  It's simple and fast, it imports almost
  anything, it's not fussy about import sources that differ in frame rate, and
  has sane export defaults geared towards YouTube.

- Olive is in a bit of a transitional state at the moment.  The most recent
  stable release is 0.1, still technically declared an alpha, released in 2019.
  However, there will never be a release 0.1.1 or 0.1.2, because development on
  the 0.1 branch has ceased.

- ``mattkc`` (a YouTuber himself, see https://www.youtube.com/c/MattKC) is the
  main developer.  He started a ground-up rewrite of the software -- which he
  calls 0.2 -- a few years back, which is still going on.  He's been working
  pretty steadily on it; every so often he sends a Patreon update.

- It is written in C++, and uses the Qt toolkit for its UI.
  https://github.com/olive-editor/olive

- I have created a fork of Olive to see if I could create a set of expressions
  that would produce an Olive 0.2 derivation.  The fork isn't really necessary,
  and it's actually kinda dumb for the Nix expressions to live there.  But
  that's where the expressions live now.

- Olive 0.2 is under very heavy development, and thus likely has a lot of rough
  edges, so I don't think it's reasonable to contribute this build to, say,
  ``nixpkgs`` (nor really even the NUR).  For instance, at the time of this
  writing, the most recent commit on master will not build at all.  It also
  doesn't yet have a lot of features I'm missing in 0.1 and I'm not trying to
  borrow trouble by packaging something I'm not going to myself use.

  But at least we can learn from trying to package a recent snapshot of it, and
  I can also get a sense of where the project is at by bumping the commit rev
  every so often and recompiling.

- Features of the nixfiles in https://github.com/mcdonc/olive/tree/nix/nix :

  - We have to use an overlay because one of Olive's dependencies is a very
    recent version of ``opencolorio``.  The overlay is in
    https://github.com/mcdonc/olive/blob/nix/nix/overlays.nix .  With the
    overlay, we specify that the version of OpenColorIO we want is v2.1.1,
    which is the lowest version that Olive 0.2 will build against.  The
    ``nixpkgs`` version is still 2.0.2.

  - I just found that this was the easiest way to feed it as an overlay to the
    import of ``nixpkgs`` in ``default.nix`` ::

      let
        pkgs = import <nixpkgs> { overlays = [ (import ./overlays.nix) ]; };
      in
      ....

    The parens around ``(import ./overlays.nix)`` is just so "import" and
    "./overlays.nix" won't be parsed as list elements.  We could have also just
    literally included the overlay code in within the overlays list but I found
    that style awful confusing, so I just moved it to a different file.

    The ``import <nixpkgs>`` here is a channel import, so it works under
    ``nix-build`` as long as we have a ``nixpkgs`` channel defined (which all
    Nix and NixOS installs do, at least out of the box).  We don't have all the
    normal things we might expect coming from editing NixOS expressions like
    the ones we get in ``/etc/nixos/configuration.nix`` (e.g. ``lib``,
    ``pkgs``, ``config``, etc).  That's because ``nix-build`` doesn't really
    work on NixOS things, it works on Nix things.  We essentially define a
    single variable named ``pkgs`` (by importing ``nixpkgs``) that we can then
    use attributes of later on.

  - For programmers that are used to more imperative languages: note that you
    might want to think of things like this (although I'm sure this explanation
    is somewhat wrong): ``import`` is not something defined by the nix language
    itself.  The AST is parsed and tokenized, and, ultimately *nixpkgs* is
    responsible for understanding what ``import`` means in the context, not the
    Nix language itself.  Things start to make sense when you understand that
    the Nix language -- in the strictest definition of that term -- is
    extremely simple and a lot of the true heavy lifting is done by dependent
    components.  I think this is actually a very, very good thing, although I
    suspect it breaks people's brains whom are new to it.

  - We have a single "native" build input.  I cargo culted this a bit by
    looking at
    https://github.com/NixOS/nixpkgs/blob/master/pkgs/applications/video/olive-editor/default.nix
    upon which my ``default.nix`` (although ending up quite different in the
    end) is based on.  What's the difference between a native build input and a
    build input?  I think native build inputs are meant to be specific to a
    particular architecture (such as amd64, arm, etc), and which won't work if
    you try to use it on an unsupported platform.  I'm not sure that ``cmake``
    is this, but it works.  The existing ``olive-editor`` nixpkg expression
    uses different native build inputs because Olive switched from qmake to
    cmake in the jump from 0.1 to 0.2.

  - We have many build inputs.  How did I figure out which ones were necessary?
    Just hackin man.  http://search.nixos.org was my friend while I ran the
    build and saw it fail at different points.  I just kept searching and
    adding things until it built.  Same with the build inputs in
    ``overlays.nix``.

- Let's see it build::

    cd ~/projects/olive/nix
    nix-build

- ``nix-build``, upon success, creates a ``result`` symlink in the current
  directory.::

    ls -al result
    lrwxrwxrwx  1 chrism users   49 Jul 24 20:56 result -> /nix/store/pqqhh18j100izqsm0q7rppzyqvn2mwdy-olive

- Within the ``result`` directory, we have a ``bin`` dir, which contains
  ``olive-editor``.  When we launch it, the program starts.

- So how repeatable is this build?  Probably not very, at least without pinning
  ``nixpkgs`` to a certain revision, because the build inputs will shift over
  time.  Indeed, if you try to build the current ``olive-editor`` from
  ``nixpkgs`` (which is 0.1), it fails because its build inputs shifted around
  over time.

- But for now, revel!  It works.

- Now, in reality, I'm not going to start to use Olive 0.2 any time soon,
  because at the moment it doesn't offer any features over 0.1 that I really
  think I need.  How would I get rid of it from the store?::

    cd ~/projects/olive/nix
    rm -rf result
    nix-collect-garbage

- Again, it's not yet time to try to contribute this to ``nixpkgs`` (nor may it
  ever be), but this work is very much requisite to being able to do so.
