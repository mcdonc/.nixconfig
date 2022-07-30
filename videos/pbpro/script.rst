Video Script
------------

- How hard could it be?  https://nixos.wiki/wiki/NixOS_on_ARM/PINE64_Pinebook_Pro

- The first step (which sounds a bit mandatory at
  https://nixos.wiki/wiki/NixOS_on_ARM/PINE64_Pinebook_Pro, but, as I came to
  understand things later, probably isn't) was to replace the U-Boot SPI
  firmware with Tow-Boot (U-Boot fork) SPI firmware.

- Downloaded and unpacked
  https://github.com/Tow-Boot/Tow-Boot/releases/download/release-2021.10-004/pine64-pinebookPro-2021.10-004.tar.xz
  .

- Flashed the Tow-Boot ``spi.installer.img`` that is in that archive to an SD
  card from an X86 system.

- My PB would not boot from the SD card.  It had not been updated in a year (or
  maybe two, the system had just been sitting idle).  The older version of
  U-Boot on its SPI made it impossible (or at least quite difficult) to boot
  from an SD card.  So I had to first update U-Boot so I could replace it.

- So I booted Manjaro off the eMMC and updated it to all latest package
  revisions (which sucked, "Enjoy the Simplicity" my ass, it's not simple to
  resolve update conflicts manually just because you haven't updated in a
  while), thinking that doing so might update U-Boot.

- That didn't automatically update U-Boot.  So I had to follow these
  instructions: https://www.jwillikers.com/update-u-boot-on-the-pinebook-pro::

    sudo dd if=/boot/idbloader.img of=/dev/mmcblk2 seek=64 conv=notrunc,fsync
    sudo dd if=/boot/u-boot.itb of=/dev/mmcblk2 seek=16384 conv=notrunc,fsyn

- Then, once I restarted, it was obvuius that the new U-Boot was installed (it
  looked different).  When I put the SD card it, and re-rebooted. it indeed
  booted from the SD, but the Tow-Boot SPI installer menu program seemed to be
  restarting itself over and over; I could not really even read the screen to
  see what the problem was because it was scrolling so fast.  (video)

- So instead of using the installer by booting from the SD card, I had to
  update the SPI with Tow-Boot from within Manjaro:
  https://github.com/Tow-Boot/Tow-Boot/issues/18 after installing ``mtd-utils``.::

    sudo nandwrite -p /dev/mtd0 Tow-Boot.spi.bin
    
  The ``Tow-Boot.spi.bin`` was on the SD card I was trying to boot from in the
  prior step, written from ``spi.installer.img``.

- 379 blocks later, Tow-Boot was on the SPI. (video)

- Aaaaand, as it became apparent after a reboot, that bricked my PB Pro.
  Apparently the upstream version of U-Boot which Tow-Boot is synced with
  (2021.10) specifically breaks the PB Pro screen.  The issue is apparently
  fixed in U-Boot 2022.01.  https://github.com/Tow-Boot/Tow-Boot/issues/139

- So I bought this cable so I could connect to the PB serially to try to
  unbrick the system:
  https://pine64.com/product/pinebook-pinephone-pinetab-serial-console/
  
- And waited for it to arrive.
