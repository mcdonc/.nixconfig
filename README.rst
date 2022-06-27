Common system config for Chris' various jawns
=============================================

A common, version-controlled set of system configurations for various NixOS
systems I own.

Usage
-----

- Build and boot a new vanilla NixOS 22.05 system with at least a ``chrism``
  user.  ``~`` below refers to this user's home directory.
  
- On the new vanilla system, add these channels as the root user::

   home-manager https://github.com/nix-community/home-manager/archive/release-22.05.tar.gz
   nixos https://nixos.org/channels/nixos-22.05
   nixos-hardware https://github.com/NixOS/nixos-hardware/archive/master.tar.gz

- Check out this repo on the new vanilla system into ``~/.nixconfig``.

- Copy an existing system from ``~/.nixconfig/<existingsystemname>`` into
  ``~/.nixconfig/<newsystemname>`` and edit the ``configuration.nix`` and
  ``hardware-configuration.nix`` files in the newly copied directory.
  
- Add a symlink from ``~/.nixconfig/<newsystemname>/configuration.nix`` to
  ``~/.nixconfig/configuration.nix``.

- Rename ``/etc/nixos/configuration.nix{,aside}`` for safety.

- Run ``sudo nixos-rebuild -I nixos-config=$HOME/.nixconfig/configuration.nix
  dry-build`` (or ``dry-activate``) to test config.

- Run ``sudo nixos-rebuild -I nixos-config=$HOME/.nixconfig/configuration.nix boot``.

- Reboot into the version-controlled environment.  Use ``ednix`` to edit the
  current configuration.  Use ``swnix`` to build and switch to an updated
  configuration.

