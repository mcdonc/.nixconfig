Chris' Nix-on-Mac Config
========================

Declarative config for multiple Macs (or just one).

- Installs several packages from Homebrew.  They are updated to their latest
  versions every time ``darwin-rebuild`` is run.

- Sets up zsh the way I like it.

- Sets up Emacs the way it like it.

- Sets up pubkeys for my user's inbound ssh.

- Ensures ssh private keys can be added to Apple Keychain via ``ssh-add``
  (eg. ``ssh-add --apple-use-keychain ~/.ssh/[your-private-key]`` ala
  https://apple.stackexchange.com/a/250572).

- Installs NerdFonts to support zsh powerlevel-10k icons.

- Configures git for first-time use.

- Configures the computer to be in dark mode.

- Makes key repeat as fast as possible.

- Turns off stupid "natural scrolling" for the touchpad.

Install Nix
-----------

Download https://install.determinate.systems/nix-installer-pkg/stable/Universal
and run it.  Say yes to all defaults.

Check out this Repository as ``~/.nixconfig``
---------------------------------------------

If you're not me, probably best to fork it first.

.. code-block::

  $ cd ~
  $ git clone <repository>

Customize for First ``nix-darwin`` Install
------------------------------------------

Make changes in the ``darwin`` subdir of the repo suitable for your
environment.

In ``flake.nix``, add a ``darwinSystem`` at the same indentation level as the
other ones, e.g., if your system is Apple Silicon:

.. code-block:: nix

      darwinConfigurations."my-macs-hostname" = nix-darwin.lib.darwinSystem {
        modules = shared-modules ++ [ homebrew-config-arm ];
        specialArgs = { inherit inputs; system="aarch64-darwin";};
      };

If your system is Intel instead of Apple Silicon, use:

.. code-block:: nix

      darwinConfigurations."my-macs-hostname" = nix-darwin.lib.darwinSystem {
        modules = shared-modules ++ [ homebrew-config-intel ];
        specialArgs = { inherit inputs; system="x86_64-darwin";};
      };

Replace ``my-macs-hostname`` with your Mac's hostname.
T
hen edit ``configuration.nix`` and change all the mentions of ``chrism`` to
your username, and possibly email addresses.  Also change the SSH pubkeys to
the one(s) you use.

For a more general overview, see
https://www.youtube.com/watch?v=Z8BL8mdzWHI&t=282s&pp=ygUKbml4LWRhcndpbg%3D%3D

Install/Run Nix-Darwin
----------------------

Initial command to both install ``nix-darwin`` and configure your system for
the first time:

``nix --extra-experimental-features "nix-command flakes" run nix-darwin -- switch --flake ~/.nixconfig/darwin``

(from https://github.com/LnL7/nix-darwin/blob/master/README.md#flakes)

It will ask for a sudo password.

It will exit for each file that it wants to manage that already exists
unmanaged on your system, and you'll need to move that file aside and rerun the
command.  Note which files you move aside, so you can put them back into place
if this stuff doesn't work out for you.

It will also attempt to install some apps from Homebrew.  I have not tried this
on a system that already has Homebrew installed, nor on one that already has
the apps it wants to install (Chrome, Firefox, others).  The (commented-out)
flags in ``configuration.nix`` for ``homebrew.autoMigrate`` and
``homebrew.onActivation.cleanup`` seem to be important here.  You can just
comment out the ``homebrew`` section in ``configuration.nix`` entirely if you
don't want to think about it.

Also, all the macs I've tried this particular config on are Intel, so if you're
on ARM, it's possible some things may not work.

Subsequent Runs of ``darwin-rebuild``
-------------------------------------

After the first run/configuration, you can play around with changes to
``configuration.nix``.  Subsequent runs to rebuild using your changes will be
just:

``darwin-rebuild switch --flake ~/.nixconfig/darwin``

There is an alias set up for this in ``configuration.nix`` so once the system
is configured once, you should be able to do instead:

``swnix``

Use https://search.nixos.org to find packages that are addable to
``environment.systemPackages``.  What goes in here are kinda like Homebrew
casks, but there are many more of them, although many Linux-only.  Adding stuff
to ``homebrew.casks`` is probably better for GUI apps, but YMMV.  Any cask you
can install imperatively via ``homebrew install`` can be added declaratively to
``homebrew.casks``.  You can mix and match between
``environment.systemPackages`` and ``homebrew.casks`` as necessaary.

There are some system-level settings set to my liking in ``system.defaults``
within ``configuration.nix``.  See ``man 5 configuration.nix`` for others
(search for ``system.defaults``).

To update all of the software Nix supplies (e.g. the stuff in
``environment.systemPackages``) as well as ``nix-darwin`` and ``nix-homebrew``
themselves, run ``nix flake update`` within the ``~/.nixconfig/darwin``
directory and rerun ``darwin rebuild switch --flake ~/.nixconfig/darwin``.

Again, for a more general overview, see
https://www.youtube.com/watch?v=Z8BL8mdzWHI&t=282s&pp=ygUKbml4LWRhcndpbg%3D%3D

Misc
----

For the ``zsh`` "powerlevel-10k" prompt to look right, you have to use a
NerdFont in the terminal like "Ubuntu Nerd Font Mono".  This must be configured
by-hand.  Also, its prompt colors are wonky in Terminal, but look correct in
iTerm.

Uninstalling
------------

I haven't tried this myself, but there is an uninstaller that is on the $PATH
named ``darwin-uninstaller`` that will uninstall ``nix-darwin`` (and presumably
all the changes it made).

To uninstall Nix itself run ``/nix/nix-installer uninstall`` or rerun the
Determinate Systems Nix GUI installer pkg.
