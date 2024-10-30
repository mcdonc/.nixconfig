Chris' Nix-on-Mac Config
========================

Install Nix
-----------

Download https://install.determinate.systems/nix-installer-pkg/stable/Universal and run it.  Say yes to all defaults.

Check out this Repository as ``~/.nixconfig``
---------------------------------------------

If you're not me, probably best to fork it first.

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

It will exit for each file that it wants to manage that already exists
unmanaged on your system, and you'll need to move that file aside and rerun the
command.

Subsequent runs to rebuild will be just:

``darwin-rebuild switch --flake ~/.nixconfig/darwin``

There is an alias set up for this in ``configuration.nix`` so once the system
is configured once, you should be able to do instead:

``swnix``

Misc
----

For the ``zsh`` "powerlevel-10k" prompt to look right, you have to use a
NerdFont in the terminal like "Ubuntu Nerd Font Mono".  This must be configured
by-hand.  Also, colors are wonky in Terminal, but look correct in iTerm.

Uninstalling
------------

I haven't tried this myself, but there is an uninstaller that is on the $PATH
named ``darwin-uninstaller`` that will uninstall ``nix-darwin`` (and presumably
all the changes it made).

To uninstall Nix itself run ``/nix/nix-installer uninstall``.
