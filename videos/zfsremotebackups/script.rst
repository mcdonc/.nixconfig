=====================================================
 NixOS 59: Remote ZFS Backups Over SSH Using Syncoid
=====================================================

- Companion to video at

- This text script available via link in the video description.

- See the other videos in this series by visiting the playlist at
  https://www.youtube.com/playlist?list=PLa01scHy0YEmg8trm421aYq4OtPD8u1SN

Script
------

- A few months ago, I made two other videos about ZFS backups:
  https://youtu.be/XRYAtldNvPo?si=T2FSG7iWdxfNdQpS

- In that video, I only configured ``syncoid`` to back up my home directory to
  an external USB enclosure.

- The backups I made were not particularly good.  I showed how to only make one
  backup generation, and if I wanted to restore from a backup older than that
  generation, I would have been out of luck.

- In the meantime, I've come to understand more fully how I can use ZFS
  snapshots in concert with ``sanoid`` to keep multiple generations of backups,
  such that I can restore from a state more than one generation old.

- ``sanoid`` is a snapshotting service by the same author.  It allows you to
  every so often take snapshots of the source.  It also allows you to prune old
  snapshots of the source and the target.

- ``syncoid`` copies any snapshots on the source to the target.  No
  configuration needed.

- NixOS service packaging of ``syncoid`` and ``sanoid`` is not dummy-proof,
  some consideration needed to use them together.

- There is a gotcha about using ``sanoid`` along with ``syncoid``.  In
  particular, you want ``sanoid`` to run more often than ``syncoid`` because if
  they continually run at the same time as each other, and at no other time,
  ``sanoid`` may not be able to prune old snapshots.

- Bonus.  Don't ask for target credentials at startup::

    # dont ask for "b/storage" credentials
    boot.zfs.requestEncryptionCredentials = lib.mkForce [ "NIXROOT" ];
    
- Bonus 2: Don't try to use "c", "e", or "L" arguments to syncoid
  ``sendOptions`` in concert with raw send ("w").  These were not problematic
  under OpenZFS 0.8, but under OpenZFS 2.0, they cause kernel panics and
  extremely high system usage.
