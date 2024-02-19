================================================
 NixOS 71: NixOS on Risc V (Milk V Duo/Duo-256M)
================================================

- Companion to video at 

- This text script available via link in the video description.

- See the other videos in this series by visiting the playlist at
  https://www.youtube.com/playlist?list=PLa01scHy0YEmg8trm421aYq4OtPD8u1SN

Risc V on Duo
=============

In his `nixos-riscv <https://github.com/NickCao/nixos-riscv>`_ repository, Nick
Cao has done the hard work of making NixOS work on two Risc V boards: the
VisionFive 2 SBC and the Milk V Duo.

The `Duo <https://milkv.io/duo>`_ has only 64MB of RAM, so it's not very
useful once NixOS is running on it; only a few meg of memory remains for useful
work. A newer Duo model named the Milk V Duo-256M has 256MB of RAM, which is
still not much, but it's a lot better than 64M.

I had a both an original Duo and a Duo 256M laying around, so I decided to try
to get NixOS running on both.

Step 1: Getting the Duo (Original) Running
------------------------------------------

- Solder some `headers
  <https://milkv.io/docs/duo/getting-started/setup#serial-console>`_ onto both
  of the Duo unit UART pins.

- I found my `USB to UART adapter
  <https://www.amazon.com/gp/product/B08ZS6H9VS/ref=ppx_yo_dt_b_search_asin_title?ie=UTF8&psc=1>`_
  (Amazon link) that I had used for other projects.  We need to use this because
  the NixOS image doesn't have neworking.

- Clone Nick's `nixos-riscv
<https://github.com/NickCao/nixos-riscv>`_ repository.

- Run `nix build nix build ".#hydraJobs.duo"` to produce a bootable image.

- Unzstd the produced image in `result/sd-image`.

- Use Balena Etcher to write the image to an SD card.

- Put the SD card into the Duo.

- Hook up the USB to UART adapter to the Duo and my machine.

- Fire up minicom.

- Watch it boot :)

Step 2: Getting the Duo 256M Running
------------------------------------

.. note::

    I had to do these steps, but you won't, because I've `created a PR
    <https://github.com/NickCao/nixos-riscv/pull/14>`_ that adds Duo 256M
    support to Nick's repo.  The description below is just for folks curious
    about how you might bring up an unsupported board.

- Fork Nick's repo.

- Update the `flake.nix` in my fork to the latest version of the
  `duo-buildroot-sdk <https://github.com/milkv-duo/duo-buildroot-sdk>`_.  I did
  this in anticipation of needing newer code than what was represented by the
  old rev that Nick chose.

- Boot an Ubuntu system (yeah I know) and go through the steps of generating an
  image using the `approved method
  <https://milkv.io/docs/duo/getting-started/buildroot-sdk>`_.  This will
  generate various `.dts`, `.dtb`, and `.bin` files that we need to support the
  new hardware.

- Put those files in the `prebuilt` directory of Nick's repo.

- Create a new nix file representing the 256M, cut and pasting Nick's `duo.nix`
  into `duo-256M.nix` and hacking on it, referencing the new prebuilt files and
  changing some Linux configuration flags.

- Flail (see diff).

- Finally produce a bootable image.

- Rinse and repeat with UART connection to the Duo 256M and minicom.

- Watch it boot :)
