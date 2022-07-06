NixOS 22: Backing Up and Restoring Your Home Directory When You Use home-manager
================================================================================

- Companion to video at https://youtu.be/vWOjaqKDrYE

- See the other videos in this series by visiting the playlist at
  https://www.youtube.com/playlist?list=PLa01scHy0YEmg8trm421aYq4OtPD8u1SN

Video Script
------------

- NixOS, at least with home-manager, is a bit special.

- home-manager puts symlinks in your home directory that point to files and
  directories somewhere within ``/nix``.

- If you simply rsync or tar up your home directory and restore into a fresh
  install it when the backup contains those symlinks, the links will be broken.

- When the links are broken, wild things can happen.  When the moon is just
  right, for example, the X server won't start.

- Solution: don't back up symlinks that point into ``/nix`` (and thus, don't
  restore any broken symlinks).

- To do this, before you back up, use ``findnixlinks.py`` at
  https://github.com/mcdonc/.nixconfig/blob/master/videos/backups/findnixlinks.py
  to generate an ``exclude-from`` list that you can use for intput to the
  ``tar`` (or rsync) command.

- The ``findnixlinks.py`` script walks your home directory looking for
  symlinks.  If it finds one, and that symlink points to a destination
  file/directory that lives anywhere within ``/nix``, it spits out the path to
  the symlink.  Thus, the output of the script contains all the symlinks you
  don't want to back up, each on one line.

- Generate the excludefrom file::

    python3 findnixlinks.py > /tmp/excludefrom.txt

- Tar up your home directory, using the excludefrom file as input::

    cd $HOME; tar cvzf /tmp/homebackup.tar.gz --exclude-from=/tmp/excludefrom.txt .

- Scp the ``homebackup.tar.gz`` to another system or copy it to a hard disk or
  whatever.

- Reinstall a new system with your generic nix config.

- Then, after NixOS is installed, at homedir restore time, just untar the
  backup file you've copied onto the fresh system while you're cd'ed to the
  home dir (ideally after you've done, e.g. ``sudo systemctl stop
  display-manager`` to stop your X/Wayland session)::

    cd $HOME; tar xvzf /tmp/homebackup.tar.gz

- Rerun ``nixos-rebuild`` for good measure.

- Restart the display manager.
  
- Bob, he becomes your uncle.
