NixOS 54: Get Started With MicroPython on a Raspberry Pi Pico In NixOS
======================================================================

- Companion to video at

- This text script available via link in the video description.

- See the other videos in this series by visiting the playlist at
  https://www.youtube.com/playlist?list=PLa01scHy0YEmg8trm421aYq4OtPD8u1SN

Script
------

- Steps to get up and running with the Pi Pico under NixOS.

- Put your user in the ``dialout`` UNIX group.  This gives you permission to
  read-from/write-to ``/dev/ttyACM0``, which will be the default "serial" port
  (emulated over USB) that the Pico can be talked to over.  For me, this looks
  something like::

    users.users.chrism = {
      extraGroups = [ "wheel" "networkmanager" "audio" "dialout" ];
    };

- Add a few requisite packages to your environment systemPackages::

   environment.systemPackages = with pkgs; [
       # ... other programs ...
       (python311.withPackages (p: with p; [
           python311Packages.pyserial # for pico-w-go in vscode
        ]))
       thonny
       vscode.fhs
       minicom
     ];

  Explanation:

  - Add Python 3.11, configured with the ``pyserial`` package needed by the
    VSCode extension ``MicroPico``, which we'll be looking at shortly.

  - Add ``thonny``, a basic MicroPython-friendly IDE.

  - Add ``vscode.fhs``, Visual Studio Code configured inside a Linux
    FHS-compliant environment.  This allows extensions to be installed and
    synchronized easily.  We need several Visual Studio Code extensions
    to be able to easily program the Pico in MicroPython.

- Run ``nixos-rebuild switch``.

- Flash your Pico with MicroPython.  Note that there are different firmware
  images for the Pico and the Pico W.  Our setup will work with either once
  your Pico is flashed.  The one for the Pico (not-W) is downloadable at
  https://micropython.org/download/RPI_PICO/ .  There are a thousand YouTube
  tutorials about how to do this, but it's essentially: connect Pico to
  computer USB with the BOOTSEL button held down, and if your Pico is working,
  a drive will be mounted.  Then copy the downloaded firmware image to the
  mounted drive.  It will then restart and the drive will vanish.  It is now
  running MicroPython.

- Once the Pico is flashed, it is ready to be communicated with.

- Open a new terminal (so that your console gets the ``dialout`` group change)
  and do ``sudo minicom -s``.  Change the ``Serial Device`` from ``/dev/modem``
  to ``/dev/ttyACM0``, press escape and ``Save as dfl``, then exit Minicom.

- Running ``minicom`` from the terminal and pressing Return a few times should
  now connect you to the Pico::

    Welcome to minicom 2.8

    OPTIONS: I18n 
    Compiled on Jan  1 1980, 00:00:00.
    Port /dev/ttyACM0, 07:12:09

    Press CTRL-A Z for help on special keys


    >>> 

- Press Ctrl-A Z Q to quit ``minicom``.

- Launch Thonny.  Visit ``Tools -> Options -> Interpreter`` and select
  ``MicroPython` from the "Which kind of interpreter..." dropdown and save the
  option.

- Press the Stop button icon in Thonny.  You should be connected to the Pico in
  the bottom frame of the window much like you were in minicom.

- I prefer to use VS Code's ``MicroPico`` to program the Pico rather than
  Thonny, in particular because it has a file synchronization feature that
  makes more sense to me than Thonny's (it will upload only changed files all
  at once, while Thonny sorta requires that you keep track of all that by hand
  and upload one at a time).

- Launch Visual Studio Code.  Click the Extensions button.  Search for
  MicroPico (it used to be called ``pico-w-go`` but it changed names).  Install
  it. Go to extension settings in the gear menu.  For ``Picowgo: Python Path``,
  set it to ``/run/current-system/sw/bin/python3.11``

- Open a new folder in VS Code, maybe a new folder in your homedir name
  picotest, then press ctrl-shift-P and search for Pico.  Select ``Pico-W-Go:
  Configure Project``.  It should show you connected to the pico in the bottom
  terminal frame.

- Have fun.



