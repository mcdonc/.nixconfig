===========================================================================
 NixOS 60: Restricting Commands a Service User Can Execute Using ``rbash``
===========================================================================

- Companion to video at

- This text script available via link in the video description.

- See the other videos in this series by visiting the playlist at
  https://www.youtube.com/playlist?list=PLa01scHy0YEmg8trm421aYq4OtPD8u1SN

Script
======

- Yesterday, I made `a video about ZFS backups over SSH using Syncoid
  <https://youtu.be/-AdppzPQuag?si=UtojkKg6O4YHjUcD>`_, at the end of which I
  complained bitterly that it's difficult to to ensure that a UNIX service
  account is permitted to run only certain executables.

- In that video I presented `a half-hearted half-solution in the form of a
  forced SSH command
  <https://github.com/mcdonc/.nixconfig/blob/master/videos/zfsremotebackups/script.rst#a-weak-lockdown-attempt>`_
  that did some sanity checking of commands received via passphraseless SSH.

- It was trivially circumventable.

- In the meantime, I hacked on a slightly less trivially circumventable
  mechanism to do the same.  It uses `Restricted Bash
  <https://www.howtogeek.com/718074/how-to-use-restricted-shell-to-limit-what-a-linux-user-can-do/>`_

- Restricted bash is just bash executed as ``rbash`` or as ``bash -r``.  It
  allows execution of only executables found on the system user's $PATH; it
  won't allow, for example the execution of ``/bin/ls``
  (``/run/current-system/sw/bin/ls`` in NixOS), but if the ``ls`` command is
  on the user's ``$PATH``, it will be executable via plain old ``ls``.  Certain
  other restrictions exist: the user can't change $PATH, ``exec`` doesn't work,
  the user can't change directories, and other things.

- I wanted to lock things down such that the only commands executable by the
  service user were ``lzop``, ``mbuffer``, ``pv``, ``zfs``, ``zpool``, and
  ``zstd``.  I had done this before with the forced ssh command but the
  interceptor script was dumb and circumventable with any use of a semicolon,
  ampersand, and other UNIX affordances, and not trivial to harden.

- ``rbash`` is almost as bad as my forced ssh command.  If you're not extremely
  careful (and even if you are), it is trivially circumventable too.  There is
  a `cottage industry of YouTube videos
  <https://www.youtube.com/watch?v=xGvjq0DxZ9s>`_ demonstrating how clever
  folks break out of ``rbash``.

- If any of the commands you offer on the user's PATH can themselves execute
  arbitrary commands, it's easy to escape the ``rbash`` sandbox.

- But it's better than nothing, and marginally better than my forced ssh
  command.
  
The Nix File
============

.. code:: nix

    { config, pkgs, home-manager, ... }:

    let
      rbash = pkgs.runCommandNoCC "rbash-${pkgs.bashInteractive.version}" { } ''
        mkdir -p $out/bin
        ln -s ${pkgs.bashInteractive}/bin/bash $out/bin/rbash
      '';

    in {
      # https://github.com/nix-community/home-manager/issues/4433
      home-manager.users.backup = { config, ... }: {
        home.stateVersion = "23.11";
        home.username = "backup";
        home.homeDirectory = "/home/backup";

        # bash the shit out of anywhere it could be falling back to
        # global config of $PATH
        home.file.".bash_profile" = {
          executable = true;
          text = ''
            export PATH=$HOME/bin
          '';
        };
        home.file.".bashrc" = {
          executable = true;
          text = ''
            export PATH=$HOME/bin
          '';
        };
        home.file.".profile" = {
          executable = true;
          text = ''
            export PATH=$HOME/bin
          '';
        };
        # https://www.reddit.com/r/NixOS/comments/v0eak7/homemanager_how_to_create_symlink_to/
        home.file."bin/lzop".source =
          config.lib.file.mkOutOfStoreSymlink "${pkgs.lzop}/bin/lzop";
        home.file."bin/mbuffer".source =
          config.lib.file.mkOutOfStoreSymlink "${pkgs.mbuffer}/bin/mbuffer";
        home.file."bin/pv".source =
          config.lib.file.mkOutOfStoreSymlink "${pkgs.pv}/bin/pv";
        home.file."bin/zfs".source =
          config.lib.file.mkOutOfStoreSymlink "${pkgs.zfs}/bin/zfs";
        home.file."bin/zpool".source =
          config.lib.file.mkOutOfStoreSymlink "${pkgs.zfs}/bin/zpool";
        home.file."bin/zstd".source =
          config.lib.file.mkOutOfStoreSymlink "${pkgs.zstd}/bin/zstd";
      };

      # Define a user account.
      users.users.backup = {
        isSystemUser = true;
        createHome = true;
        home = "/home/backup";
        group = "backup";
        shell = "${rbash}/bin/rbash";
        extraGroups = [ ];
        openssh = {
          # https://stackoverflow.com/a/50400836 ; prevent
          # ssh backup@optinix.local -t "bash --noprofile" via no-pty
          authorizedKeys.keys = [
            "no-port-forwarding,no-X11-forwarding,no-agent-forwarding,no-pty ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINLuqK/tjXwfiMpOVw3Kk2N24BbEoY3jT4D66WvYGS0v chrism@thinknix512"
          ];
        };
      };

      users.groups.backup = { };

    }

Key Points
==========

- We create an ``rbash`` executable, which is just a symlink to ``bash``.  When
  ``bash`` is executed as ``rbash``, it uses restricted mode.

- We set the ``backup`` system user's shell to ``rbash``.

- We create a ``bin`` directory in the service user's homedir and fill it with
  links to commands that ``syncoid`` needs to execute.  These will be the only
  programs that are executable by the ``backup`` user except for bash builtins.

- We add ``.bash_profile``, ``.profile``, and ``.bashrc`` dotfiles with the
  same content.  Without bashing the crap out of various dotfiles, the global
  user config is executed, adding to $PATH in some circumstances.  Just nuke em
  all.

- Without ``no-pty`` in the ssh authorized key, the following is a trivial
  escape of ``rbash``::

    ssh backup@optinix.local -t "bash --noprofile"

- With the mitigations in place, is this secure?  Who knows!  Almost certainly
  not. Maybe there's a ``zfs shell`` command, or an ``lzop shell`` command.
  Maybe the maintainers of bash have given up on ``rbash`` and there's some
  zero-day key combination from 1988 or other nefarious escape mechanism laying
  in wait.  I have no idea.  But as the suspenders part of belt and suspenders,
  where the belt part is ensuring the security of the private key, it's
  something.
