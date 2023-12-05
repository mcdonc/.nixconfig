=====================================================
 NixOS 59: Remote ZFS Backups Over SSH Using Syncoid
=====================================================

- Companion to video at

- This text script available via link in the video description.

- See the other videos in this series by visiting the playlist at
  https://www.youtube.com/playlist?list=PLa01scHy0YEmg8trm421aYq4OtPD8u1SN

Overview
========

- A few months ago, I made two other videos about ZFS backups:
  https://youtu.be/XRYAtldNvPo?si=T2FSG7iWdxfNdQpS (original) and
  https://www.youtube.com/watch?v=csUXgtyZUGw (revisited).

- In those videos, I only configured ``syncoid`` to back up the home directory
  of the machine local to the USB enclosure I'm using as a backup target.

- Since then, I've set things up such that I am now backing up the home
  directory of a remote machine also.

- Note that the source dataset and the target dataset in my case are encrypted.

- You will be able to get the gist of things by watching this video only but
  some ZFS knowledge is assumed.  I suggest that if you run into problems, you
  watch the other two videos;

Prerequisites
=============

- We need to create a passphraseless SSH public/private keypair (don't worry,
  this isn't my actual backup key) and save it in our home directory as
  ``backup.key`` and ``backup.key.pub``::

    $ ssh-keygen
    Generating public/private ed25519 key pair.
    Enter file in which to save the key (/home/chrism/.ssh/id_ed25519): /home/chrism/backup.key
    Enter passphrase (empty for no passphrase): 
    Enter same passphrase again: 
    Your identification has been saved in /home/chrism/backup.key
    Your public key has been saved in /home/chrism/backup.key.pub
    The key fingerprint is:
    SHA256:+i0G1T38Bp7aFyKtsxZuGqZhc+Ooa/OGQe3rtELXrg0 chrism@thinknix512
    The key's randomart image is:
    +--[ED25519 256]--+
    |                 |
    |                 |
    |     .   . o     |
    |    . . . . =    |
    |   . . oS  o =   |
    |    o +.. o = +  |
    |   . +E+=. * o . |
    |    =oo&++B . .  |
    |   .oOBo==oo .   |
    +----[SHA256]-----+
   
- We are going our *pull* our backups from the remote machine.  This means that
  the machine with the USB enclosure and lots of disk space will be our backup
  *target* and it will attempt to contact the backup *source* machine via SSH.

- On the *target* machine, take the ``backup.key`` we generated and copy it to
  ``/var/lib/syncoid/backup.key`` and give it world-readable permission (it's
  less bad than it sounds, the directory itself cannot be traversed by anyone
  buut ``syncoid`` and ``root`` users)::

    $ sudo cp /home/chrism/backup.key /var/lib/syncoid
    $ sudo chmod o+r /var/lib/syncoid/backup.key

  Note that the key cannot live anywhere else if you want to use it with
  syncoid.  The ``syncoid`` user which it runs under seemingly can see nowhere
  else.

- If you don't have the ``var/lib/syncoid`` directory yet on your target
  machine, I *think* it gets created when syncoid is either installed or maybe
  when it attempts to sync at least one source.  This is what its permissions
  are on my system::

    $ cd /var/lib
    $ ls -al|grep syncoid
    drwx------  3 syncoid       syncoid         4 Dec  4 20:04 syncoid

- In the Nix config of your *source* system, add configuration for a ``backup``
  user that includes the public side of the authorized key (the contents of
  ``backup.key.pub``)::

    users.users.backup = {
      isNormalUser = true;
      createHome = false;
      home = "/var/empty";
      extraGroups = [ ];
      openssh = {
        authorizedKeys.keys = [
          ''ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINLuqK/tjXwfiMpOVw3Kk2N24BbEoY3jT4D66WvYGS0v chrism@thinknix512''
        ];
      };
    };
    
- Once you rebuild your source system using ``nixos-rebuild switch``, you
  should be able to ssh from your target system to your source system.  My
  source system is called ``optinix.local``::

    $ sudo ssh -i /var/lib/syncoid/backup.key backup@optinix.local

  Sudo is required here only to be able to read the key.  I'll try to provide
  suggestions to lock this down a bit more in upcoming instructions, but it is
  what it is.

- On your *source* system, give some ZFS permissions to the backup user on the
  dataset that you want to back up.  These are necessary for syncoid to do its
  job::

    sudo zfs allow backup compression,hold,send,snapshot,mount NIXROOT/home

Making It Go
============

- On your target system, configure a ``services.syncoid`` command to pull from
  the source system dataset (in my case, ``NIXROOT/home``, the dataset that has
  my home directory data in it) in your Nix configuration, and a
  ``services.sanoid`` dataset to keep around historical snapshots of the
  dataset, which we can use to restore from if we have data loss. The dataset
  that I'm backing up to is ``b/optinix-home`` (I have a ``b`` zpool that is my
  big USB enclosure).

  We'll also add a few programs to our system packages that syncoid uses to
  better transfer data.::

    services.syncoid = {
      enable = true;
      interval = "daily";
      commonArgs = [ "--debug" ];
      commands = {
        "optinix-home" = {
          sshKey = "/var/lib/syncoid/backup.key";
          source = "backup@optinix.local:NIXROOT/home";
          target = "b/optinix-home";
          sendOptions = "w c";
          extraArgs = [ "--sshoption=StrictHostKeyChecking=off" ];
        };
      };
    };

    services.sanoid = {
      enable = true;
      interval = "hourly"; # run this hourly, run syncoid daily to prune ok
      datasets = {
        "b/optinix-home" = {
          autoprune = true;
          autosnap = false;
          hourly = 0;
          daily = 7;
          weekly = 4;
          monthly = 12;
          yearly = 0;
        };
      };
      extraArgs = [ "--debug" ];
    };

    environment.systemPackages = with pkgs; [
      # used by zfs send/receive
      pv
      mbuffer
      lzop
      zstd
    ];
    
- On your source system, configure a ``services.sanoid`` dataset to keep around
  a few historical datasets, and also add some system packages for use by
  syncoid::

      services.sanoid = {
        enable = true;
        interval = "hourly"; # run this hourly, run syncoid daily to prune ok
        datasets = {
          "NIXROOT/home" = {
            autoprune = true;
            autosnap = true;
            hourly = 0;
            daily = 1;
            weekly = 1;
            monthly = 1;
            yearly = 0;
          };
        };
        extraArgs = [ "--debug" ];
      };

      environment.systemPackages = with pkgs; [
        # used by zfs send/receive
        pv
        mbuffer
        lzop
        zstd
      ];

A Weak Lockdown Attempt
=======================

- Passphraseless SSH keys make me very nervous.

- The UNIX user on the source system cannot have a ``/bin/nologin`` shell
  because syncoid indeed needs to execute the shell via SSH from the target to
  run commands.

- I attempted to ameliorate this by using a ``command=ascript`` stanza in the
  beginning of the ssh key of the backup user, which forces the machine to run
  that script when it's contacted via ssh.  When the machine is contacted, that
  script is run and the original command checked, and only if it's permitted by
  the script will the original command run::

    let
      restrictbackup = pkgs.stdenv.mkDerivation {
        name = "restrictbackup";
        dontUnpack = true;
        installPhase = "install -Dm755 ${./restrictbackup.py} $out/bin/restrictbackup";
        buildInputs = [ pkgs.python311 ];
      };

    in
      # Define a user account.
      users.users.backup = {
        isNormalUser = true;
        createHome = false;
        home = "/var/empty";
        extraGroups = [ ];
        openssh = {
          authorizedKeys.keys = [
            ''command="${restrictbackup}/bin/restrictbackup" ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINLuqK/tjXwfiMpOVw3Kk2N24BbEoY3jT4D66WvYGS0v chrism@thinknix512''
          ];
        };
      };

  Where ``restrictbackup.py`` has these contents::

     #!/usr/bin/env python3
     import os

     sh = "/run/current-system/sw/bin/sh"

     allowed = ("exit", "echo", "command", "zpool", "zfs")

     # This would require a lot more work to be truly secure
     # (anticipate ";", "&", "&&", $(cmd), `cmd` injection).
     # It'd be a project.

     if __name__ == "__main__":

         original = os.environ.get('SSH_ORIGINAL_COMMAND', '').strip()

         if original:

             f = open('/tmp/commands', 'a')

             f.write(original + '\n')

             for name in allowed:
                 if original.startswith(name):
                     os.execvp(sh, [sh, "-c", original]) # no need to break

  This is terrible.  It's more of a recommendation to potential intruders
  please don't do this than a lockdown because of the potential for command
  separator (";", "&", etc) injection.

- We also have problematic ZFS permissions granted to the ``backup``
  user, but they are non-optional (e.g. ``destroy``).

- See also https://github.com/jimsalterjrs/sanoid/issues/82

- Hit me up if you have any ideas.

