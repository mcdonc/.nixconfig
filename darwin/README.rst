Chris' Nix-on-Mac Config
========================

Install Nix
-----------

- Download https://install.determinate.systems/nix-installer-pkg/stable/Universal and run it.  Say yes to all defaults.

Check out this Repository as ``~/.nixconfig``
---------------------------------------------

.. code-block:: bash
  $ cd ~
  $ git clone <repository>

Customize
---------

Make changes in the ``darwin`` subdir of the repo suitable for your
environment.

Install Nix-Darwin and Configure Your System
--------------------------------------------

nix --extra-experimental-features "nix-command flakes" run nix-darwin -- switch --flake ~/.nixconfig/darwin

(from https://github.com/LnL7/nix-darwin/blob/master/README.md#flakes)

Subsequent runs to rebuild will be just ``darwin-rebuild switch --flake
~/.nixconfig/darwin``.
