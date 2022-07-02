- What's the best way to get set up to contribute code representing new systems
  (e.g. P50, P51, P52) to nixos-hardware?  To test it, should I just do a
  checkout of the nixos-hardware repo, and, in my configuration, instead of
  pointing at a channel, point at newly created nix code for the hardware in
  the checkout, and assume when people use the nixos-hardware channel it will
  work?

- I currently have to install ``olive-editor`` (video editor) by hand because
  the build is broken (https://hydra.nixos.org/build/173379959).  I currently
  use ``nix-env`` to get the last known working build::

    nix-env -i /nix/store/4nq5wfa01vq6x00q8k777qhf47bp2wd4-olive-editor-0.1.2 --option binary-caches https://cache.nixos.org

  Is there a way to do this declaratively in my configuration instead?
  
