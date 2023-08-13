NixOS 53: ZFS Backups Using Syncoid
===================================

- Companion to video at

- This text script available via link in the video description.

- See the other videos in this series by visiting the playlist at
  https://www.youtube.com/playlist?list=PLa01scHy0YEmg8trm421aYq4OtPD8u1SN

Overview
--------

- My root and home filesystems on all my systems are ZFS datasets.

- Because I use NixOS, there isn't much point in backing up their root
  datasets, but backing up their home datasets is critical.

- I'll use ```syncoid`` to do this; it is a ZFS-specific backup tool written by
  Jim Salter that uses ``zfs send`` and ``zfs receive`` under the hood.  Jim
  gave a talk about the project that contains ``syncoid`` a while back which
  was recorded at https://www.youtube.com/watch?v=cDWiZwMqAxI&t=846s

- ``zfs send`` sends only changes, kinda like rsync, but better, because it has
  intimate knowledge of ZFS internals, so it can do block-level computation of
  changes and needn't use brute-force heuristics to divine what changed between
  backup runs.  I made a video about using "raw" ZFS send/receive to do backups
  a while back at https://youtu.be/NHM2T0uxkUM that explains what they do.  We
  use ``syncoid`` instead of raw send/receive because it automatically handles
  cleaning up old snapshots for us.

- ``syncoid`` can either be used locally to back up a dataset in one pool to
  another, or it can be used over ``ssh`` to back up to a remote pool.  In this
  video, we will only see it used to back up a dataset to a different ZFS pool
  on the same local machine.  Doing the same over ssh is pretty trivial.

Creating the Target Pool
------------------------

- I have two 5TB drives in a USB enclosure that I'd like to mirror and put into
  a backup pool, and I'd like then to use that pool as the target pool for my
  backups.

- I initialized the 5TB disks that will contain the backup pool.  To destroy
  any GPT metadata and partitions that are laying around on those disks, (let's
  say they're called ``/dev/sda`` and ``/dev/sdb``), I used ``sgdisk
  --zap-all``::

    sudo sgdisk --zap-all /dev/sda
    sudo sgdisk --zap-all /dev/sdb

  To get ``sgdisk``, install ``gptfdisk`` in your systemPackages list::

    environment.systemPackages = [ gptfdisk ];

- I then created a ZFS pool named ``b`` on the two 5TB drives in a mirrored
  configuration.  But instead of using the common name of the devices to tell
  ZFS which devices I want to put the pool on, I used the ``/dev/disk/by-id``
  alias of each instead of ``/dev/sda`` / ``dev/sdb``, which avoids problems in
  the future when the order that the disks are detected in at machine start
  time changes.::

    sudo zpool create \
         -o ashift=12 \
         -o autotrim=on \
         -O compression=lz4 \
         -O acltype=posixacl \
         -O xattr=sa \
         -O relatime=on \
         -O normalization=formD \
         -O dnodesize=auto \
         b \
         mirror \
         /dev/disk/by-id/usb-ST5000LM_000-2AN170_180705123C22-0:0 \
         /dev/disk/by-id/usb-ST5000LM_000-2AN170_180705123C21-0:0

- I can cause this new pool to be automatically imported at boot time using the
  ``boot.zfs.extraPools`` directive inside the Nix configuration that is used
  for the host that the drives are connected to.::

    boot.zfs.extraPools = [ "b" ];

- It's probably a good idea to reboot now to see if the ``b`` pool is
  automatically imported at system startup.  For me, it is::

     zpool list|cut -f1 -d' '
     NAME
     NIXROOT
     b

  If you would rather not reboot, do::

    sudo zpool import b

Doing Backups
-------------
  
- For now, I'm only concerned about backups of the ``NIXROOT/home`` dataset
  that is on the same physical machine as the ``b`` zpool.

- The name of the zpool that my ``home`` dataset is in is called ``NIXROOT``::

    $ zfs list -r NIXROOT
    NAME               USED  AVAIL     REFER  MOUNTPOINT
    NIXROOT            641G   258G      192K  none
    NIXROOT/home       530G   258G      530G  legacy
    NIXROOT/reserved     1G   259G      192K  none
    NIXROOT/root       111G   258G      111G  legacy
    
  But, because my ``home`` dataset is rather large, for the purposes of this
  video, I'll be demonstrating backups of a smaller dataset in the pool named
  ``test``, created via::

    sudo zfs create -o mountpoint=/test NIXROOT/test

  It will house randomly created files for purposes of this demo.

- To start backups, I added this to my host configuration::

      services.syncoid = {
        enable = true;
        interval = "*:0/15";
        commands = {
          "NIXROOT/test" = {
            target = "b/thinknix512-test";
            sendOptions = "w";
            extraArgs = [ "--debug" ];
          };
        localSourceAllow =
           options.services.syncoid.localSourceAllow.default ++ [ "mount" ];
        localTargetAllow =
           options.services.syncoid.localTargetAllow.default ++ [ "destroy" ];
        };

- Note that the ``NIXROOT`` pool has encryption enabled at the pool level.
  This means all datasets created in the pool share the same encryption
  settings.

  The ``b`` pool does *not* have encrypted enabled because we don't want to
  have to type its passphrase every time we boot.  But we can make sure that
  the ``NIXROOT/test`` dataset sent over does not abandon its dataset-inherited
  encryption settings during the backup by using "raw send".
  
- The ``w`` send option ("raw send") makes sure that the encryption on the
  source dataset isn't undone in the backup.  The ``-debug`` in ``extraArgs``
  is just so we can see that things are happening under journalctl for purposes
  of this video, but I'll probably eventually remove it.  Changing the
  ``interval`` causes syncoid to be run every minute for purposes of this
  video, so I don't have to wait long for it to start, but eventually we'll
  change this to something saner too (e.g. ``daily``).

- The ``localSourceAllow`` and ``localTargetAllow`` lines work around a bug in
  the Nix packaging of ``syncoid`` which prevents ``syncoid`` ZFS snapshots
  from being destroyed when they are no longer necessary.

- ``syncoid`` works in its default mode by managing a single ZFS snapshot on
  each the source dataset and the target dataset.::
  
   $zfs list -t snap -r NIXROOT/test|cut -f1 -d' '
   NAME
   NIXROOT/test@syncoid_thinknix512_2023-08-13:14:10:27-GMT-04:00

   $ zfs list -t snap -r b/test-thinknix512|cut -f1 -d' '
   NAME
   b/thinknix512-test@syncoid_thinknix512_2023-08-13:14:12:08-GMT-04:00

- In a more conscientous setup, we would use a tool like ``sanoid`` or
  ``zfs-auto-snapshot`` to keep a set of yearly/monthly/weekly/daily snapshots
  on the source dataset and configure ``syncoid`` to make sure we copy these
  snapshots to the target.  But I don't think I really have the space in my
  ``NIXROOT`` ZFS pool to keep around all the old grandfather-father-son
  snapshot data.

  ``syncoid`` as configured above appears to remove all but the most recent
  snapshot it creates, so when I switch its interval to ``daily``, I'll be able
  to restore from at most data from a day ago.  That's fine for my purposes
  until I put my home dir on a larger disk (any backup is better than no
  backup).

  You might think it would be possible to just every so often snapshot the
  *target* dataset in order to get grandfather-father-son backups.  But no.
  Successful ZFS replications using ``syncoid`` destroy any snapshots on the
  target later than the most recent previous snapshot.  See
  https://github.com/jimsalterjrs/sanoid/issues/558#issuecomment-643642861 .
  This isn't the fault of ``syncoid``.  ZFS snapshots aren't like Git branches,
  they need to be temporally contiguous over time.  Thus, any shenanigans with
  snapshots has to be done on the source.

- Here is the source of a file named ``changerand.py`` that I'll use in the
  following demo step::

    import time
    import uuid
    while 1:
        new_id = uuid.uuid4().hex
        f = open(new_id, "w")
        f.write('data')
        f.close()
        print(f"wrote {new_id}")
        time.sleep(30)

- To see our newly replicated dataset, we will need to ``sudo zfs load-key
  b/thinknix512-test; sudo zfs mount b/thinknix512-test``.
  
- Demo: Run ``changerand.py`` within ``NIXROOT/test``, run ``journalctl -f``,
  run ``watch zfs list -t snap -r b/thinknix512-test NIXROOT/test``, ``watch ls
  /b/thinknix512-test``, ``watch ls /NIXROOT/test`` all in separate terminals.

- Not much sense in trying a restore; we can see with our own eyes that the
  target dataset matches the source, and the only real test we need to do is to
  be able to mount it.
