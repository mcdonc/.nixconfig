Video Script
------------

- The first step (which sounds a bit mandatory at
  https://nixos.wiki/wiki/NixOS_on_ARM/PINE64_Pinebook_Pro, but, as I came to
  understand things later, probably isn't) was to replace the U-Boot SPI
  firmware with Tow-Boot (U-Boot fork) SPI firmware.

- Flashed the Tow-Boot spi.installer.img to an SD card from an X86 system.

- My PB would not boot from the SD card.

- My PBPro had not been updated in a year (or maybe two), and its U-Boot was
  quite old.  So I had to first update U-Boot so I could replace it.

- So I first updated Manjaro (which sucked, "Enjoy the Simplicity" my ass, it's
  not simple to resolve update conflicts manually just because you haven't
  updated in a while).

- That didn't automatically update U-Boot.  So I had to follow these
  instructions: https://www.jwillikers.com/update-u-boot-on-the-pinebook-pro

- Then, once I rebooted, the new U-Boot was installed.  When I put the SD card
  it, it indeed booted from it, but the Tow-Boot SPI installer menu program
  seemed to be restarting itself over and over; I could not really even read
  the screen to see what the problem was because it was scrolling so fast.

- So instead of using the installer by booting from the SD card, I had to
  update the SPI with Tow-Boot from within Manjaro:
  https://github.com/Tow-Boot/Tow-Boot/issues/18 after installing mtd-utils.::

    sudo nandwrite -p /dev/mtd0 Tow-Boot.spi.bin
    
  The ``Tow-Boot.spi.bin`` was on the SD card I was trying to boot from in the
  prior step, written from ``spi.installer.img``.

- 379 blocks later, Tow-Boot was on the SPI.

- Aaaaand, as it became apparent after a reboot, that bricked my PB Pro.
  Apparently the upstream version of U-Boot which Tow-Boot is synced with
  (2021.11) specifically breaks the PB Pro screen.  The issue is apparently
  fixed in U-Boot 2022.01.  https://github.com/Tow-Boot/Tow-Boot/issues/139

- So I bought this cable so I could connect to the PB serially to try to
  unbrick the system:
  https://pine64.com/product/pinebook-pinephone-pinetab-serial-console/
  
- Then I'll have to wait 
