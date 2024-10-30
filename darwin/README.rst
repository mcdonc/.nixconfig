Chris' Nix-on-Mac Config
========================

Install Nix
-----------

- Download https://install.determinate.systems/nix-installer-pkg/stable/Universal and run it.  Say yes to all defaults.

Check out this Repository as ``~/.nixconfig``
---------------------------------------------

.. code-block::

  $ cd ~
  $ git clone <repository>

Customize
---------

Make changes in the ``darwin`` subdir of the repo suitable for your
environment (mostly to ``configuration.nix`` probably).

Install Nix-Darwin and Configure Your System
--------------------------------------------

Initial command to both install ``nix-darwin`` and configure your system for
the first time:

``nix --extra-experimental-features "nix-command flakes" run nix-darwin -- switch --flake ~/.nixconfig/darwin``

(from https://github.com/LnL7/nix-darwin/blob/master/README.md#flakes)

Subsequent runs to rebuild will be just:

``darwin-rebuild switch --flake ~/.nixconfig/darwin``

Misc
----

For the ``zsh`` "powerlevel-10k" prompt to look right, you have to use a
NerdFont in the terminal like "Ubuntu Nerd Font Mono".  This must be configured
by-hand.  Also, colors are wonky in Terminal, but look correct in iTerm.
