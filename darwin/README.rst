Chris' Nix-on-Mac Config
========================

Declarative config for multiple Macs.

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
environment.

In ``flake.nix``, add a ``darwinSystem`` at the same indentation level as the
other ones, e.g.:

.. code-block:: nix

      darwinConfigurations."my-macs-hostname" = nix-darwin.lib.darwinSystem {
        modules = shared-modules ++ [ homebrew-config-arm ];
        specialArgs = { inherit inputs; system="aarch64-darwin";};
      };

Replace ``my-macs-hostname`` with your Mac's hostname.

If your system is Intel instead of Apple Silicon, use:

.. code-block:: nix

      darwinConfigurations."my-macs-hostname" = nix-darwin.lib.darwinSystem {
        modules = shared-modules ++ [ homebrew-config-intel ];
        specialArgs = { inherit inputs; system="x86_64-darwin";};
      };

Then edit ``configuration.nix`` and change all the mentions of ``chrism`` to
your username, and possibly email addresses.

For a more general overview, see https://www.youtube.com/watch?v=Z8BL8mdzWHI&t=282s&pp=ygUKbml4LWRhcndpbg%3D%3D

Install Nix-Darwin and Configure Your System
--------------------------------------------

Initial command to both install ``nix-darwin`` and configure your system for
the first time:

``nix --extra-experimental-features "nix-command flakes" run nix-darwin -- switch --flake ~/.nixconfig/darwin``

(from https://github.com/LnL7/nix-darwin/blob/master/README.md#flakes)

It will ask for a sudo password.

It will exit for each file that it wants to manage that already exists
unmanaged on your system, and you'll need to move that file aside and rerun the
command.

It will also attempt to install some apps from Homebrew.  I have not tried this
on a system that already has Homebrew installed, nor without the apps it wants
to install (Chrome, Firefox, others).  The (commented-out) flag in
``configuration.nix`` for ``homebrew.autoMigrate`` seems to be important here.

Also, all the macs I've tried this particular config on are Intel, so if you're
on ARM, it's possible some things may not work.

Subsequent Runs of ``nixos-rebuild``
------------------------------------

After the first run/configuration, you can play around with changes to
``configuration.nix``.  Subsequent runs to rebuild using your changes will be
just:

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

To uninstall Nix itself run ``/nix/nix-installer uninstall`` or rerun the GUI
installer pkg.
