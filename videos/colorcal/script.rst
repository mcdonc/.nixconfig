NixOS 40: Monitor Color Calibration
===================================

- Companion to video at ...

- See the other videos in this series by visiting the playlist at
  https://www.youtube.com/playlist?list=PLa01scHy0YEmg8trm421aYq4OtPD8u1SN

Video Script
------------

- I'm not a professional artist.  I don't really need this.  But it can be fun
  and informative to see what is intended by those kinds of people on your
  monitor, instead of whatever blown-out all-blue profile your monitor vendor
  shipped it with.  For instance, did you know that the Ubuntu GNOME theme
  toolbar is actually *brown*, not mud-gray?

- Color calibration is of course not really a NixOS thing, but, if you're on
  NixOS 22.05, you won't have access to the go-to color calibration GUI for
  Linux called DisplayCAL.  Apparently DisplayCAL is written in Python 2.X, and
  such apps aren't supported under NixOS. But DisplayCAL is really just a GUI
  wrapper around ArgyllCMS, which is supported on NixOS.  The process can be
  done with "raw" ArgylCMS and another tool named ``xcalib``; it is a little
  more manual but still doable.

- The colorimiter I'm using is a Pantone Huey.  You can get one new on ebay for
  like $15-$20, shipped.  Don't bother with the Pro version, AFAICT.  The only
  difference is software, which you can't use under Linux anyway.
  https://www.ebay.com/itm/165593425452?hash=item268e23262c:g:v9wAAOSw0Nti3OHT

- Output of ``lsusb`` for the device.::

    Bus 001 Device 016: ID 0971:2005 Gretag-Macbeth AG Huey

- Add ``argyllcms`` and ``xcalib`` into environment.systemPackages and
  rebuild::

    environment.systemPackages = with pkgs; [
      # ...
      argyllcms
      xcalib
      # ...
    ];


- Make sure your monitor won't turn off or go dim due to its internal poweroff
  and energy settings.  Maybe wipe it down a bit.  I think ``dispcal`` shuts
  off the screen lock while it's running but YMMV depending on your setup, so
  it might not be a bad idea to turn off any screen lock or blanking you have.
  Maybe disable any "night color" (red-shift) software you have.  Optionally,
  set your screen wallpaper to an all-black color and hide any icons or docks
  on the screen.  I'm not sure if this is required for LCD monitors, but I do
  it for good measure.  I also turn off the lights in the room.

- Invoke ``dispcal``, tellng it to output an ICC profile::

    sudo dispcal -o monprofile

- Attach the Huey over the colored swatch and and confirm.
  
- Choose "7", "Continue on to calibration" when prompted and watch the swatch
  cycle, seemingly forever but more like 30 minutes.
  
- After waiting forever, two files will be generated: ``monprofile.icc`` and
  ``monprofile.cal`` and ``dispcal`` will exit.

- To test it out::

    xcalib -s :0 monprofile.icc

- To make sure it happens every time you log in, put the following in your
  NixOS configuration's home-manager section.  If you don't yet have
  home-manager, you'll have to set it up (see
  https://nix-community.github.io/home-manager/index.html)::

    xdg.configFile."autostart-scripts/localxcalib.sh" = {
      text = ''
        #!/bin/sh
        set -x
        f="${config.xdg.configHome}/monprofile.icc"
        if [ -e "$f" ]; then xcalib -s :0 "$f"; else echo "no file $f"; fi
      '';
      executable = true;
    };
    
  Then, move the generated ``monprofile.icc`` such that it's in
  ``$HOME/.config/monprofile.icc``, and log out and log back in to test it.

- When you relogin, to see whether it worked or not, run::

    sudo journalctl -b0

  And search for ``monprofile``. 
