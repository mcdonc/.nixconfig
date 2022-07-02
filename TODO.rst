- What's the best way to get set up to add hardware to nixos-hardware?
  Just do a checkout and instead of the channel point at the newly
  created model in the checkout?

- I have to install olive-editor by hand.  How do I not do that?

  nix-env -i /nix/store/4nq5wfa01vq6x00q8k777qhf47bp2wd4-olive-editor-0.1.2 --option binary-caches https://cache.nixos.org

  because of https://hydra.nixos.org/build/173379959
