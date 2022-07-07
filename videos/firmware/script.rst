NixOS 23: Making Recalcitrant Hardware Work (aka Why-Doesnt-My-Wireless-Work)
=============================================================================

- Companion to video at ...

- See the other videos in this series by visiting the playlist at
  https://www.youtube.com/playlist?list=PLa01scHy0YEmg8trm421aYq4OtPD8u1SN

Video Script
------------

- On the Thinkpad P50/P51/P52, out of the box, Wifi does not work under NixOS.

- The Linux kernel, as it boots, is capable of feeding firmware images into
  various pieces of hardware in your system.

- If firmware is not uploaded to some hardware at boot time, the device won't
  work.  This is true even if the kernel supports the hardware via a driver.

- Show wireless list empty.

- ``journalctl -k -e`` will show things like this::

    Jul 07 11:47:11 thinknix512 kernel: iwlwifi 0000:04:00.0: no suitable firmware found!
    Jul 07 11:47:11 thinknix512 kernel: iwlwifi 0000:04:00.0: minimum version required: iwlwifi-8265-22
    Jul 07 11:47:11 thinknix512 kernel: iwlwifi 0000:04:00.0: maximum version supported: iwlwifi-8265-36
    Jul 07 11:47:11 thinknix512 kernel: iwlwifi 0000:04:00.0: check git://git.kernel.org/pub/scm/linux/kernel/git/firmware/linux>    

- Q: Why do things always suck?  A: Politics.  You need to flip a political
  switch to get your hardware working.

- You need to set ``hardware.enableAllFirmware`` to true in order for the
  firmware images to be present on your system, available for upload to the
  devices at boot time.
  https://search.nixos.org/options?channel=22.05&show=hardware.enableAllFirmware&from=0&size=50&sort=relevance&type=packages&query=hardware.enable

- There is also ``hardware.enableRedistributableFirmware``, which puts a subset
  of firmware images, those which are deemed legally redistributable, on your
  system.  It's often set to true just in a base install, especially if you use
  the ``nixos-hardware`` repository.  But this is not enough for P50/P51/P52
  Wifi.  Also not enough for P52 sleep.

- Can get a long way without needing either flag, but only so far.

- Flip the switch, reboot.

- Show wireless GUI working.

- Now in journalctl -k::

    iwlwifi 0000:04:00.0: loaded firmware version 36.ca7b901d.0 8265-36.ucode op_mode iwlmvm

- I have a couple of PRs open to nixos-hardware which, if accepted, should set
  ``hardware.enableAllFirmware`` true for P50/P51/P52.  Not sure if this is
  politically kosher.
