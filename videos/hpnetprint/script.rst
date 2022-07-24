NixOS 36: Using An HP Network Printer (HP M148fdw)
==================================================

- Companion to video at ...

- See the other videos in this series by visiting the playlist at
  https://www.youtube.com/playlist?list=PLa01scHy0YEmg8trm421aYq4OtPD8u1SN

Video Script
------------

- Man I love NixOS.  If there's one thing I hate it's printing.  I'm reasonably
  confident that once I've figured it out (which I now have), that I will
  *never* *ever* have to think about this again.

- I have an HP network printer.  It is, I guess, one of those JetDirect things,
  with an Ethernet Jack.  It can be printed to in any of 27 ways.

- The only option anyone *really* needs is::

    services.printing.enable = true;

- This turns on CUPS, which you can then access at http://localhost:631/ .
  CUPS lets you add and configure printers imperatively.  Or you can use, in
  KDE at least, the ``Printers`` app to do the same thing.  Note that the
  username and password it asks you for when you add or modify printer stuff is
  just your normal username and password.

- You can stop watching if you don't care about configuring your printer
  declaratively.

- But if you do care, because you hate that shit, and you have multiple NixOS
  systems in your place, I'm your man.

- One way to do it, mostly useful for printers connect through USB (or god
  forbid, Centronics; shout out if you remember those) is to use the
  ``hardware.printers.ensurePrinters`` option.  It takes a list of sets.::

    hardware.printers = {
      ensureDefaultPrinter = "HP";
      ensurePrinters = [{
        name = "HP";
        location = "downstairs";
        model = "everywhere";
        description = "ChrisM HP LaserJet Pro M148fdw";
        deviceUri = "ipp://192.168.1.190/ipp";
      }];
    };

- This option enables a service that, every so often, writes a printer into the
  CUPS config, overwriting any other printer of the same name.

- *But* it wasn't the right option for me because I have this kinda-awesome HP
  network printer, and when I did that, it wouldn't let me print double-sided
  because it couldn't quite figure out the right driver to use.

- So, instead, I did this::

    services.avahi.enable = true;
    services.avahi.nssmdns = true;

- Now my printer is just automatically available in CUPS configuration on all
  my systems.  Bob, uncle.

- ``ensurePrinters`` and ``services.avahi.enable`` etc are kinda mutually
  exclusive in my case, because if I have both, two printers (both the same
  printer) will show up.  I've also seen reports that if you use ``ipp``
  printers under ``ensurePrinters``, that ``nixos-rebuild`` will not work if
  you aren't connected to the same network as the printer, or if the printer is
  offline.
