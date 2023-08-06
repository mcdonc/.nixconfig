NixOS 51: Using Plasma-Manager to Configure Per-User Plasma Desktop Settings
============================================================================

- Companion to video at https://www.youtube.com/watch?v=2r0KnIZX5HY

- This text script available via link in the video description.

- See the other videos in this series by visiting the playlist at
  https://www.youtube.com/playlist?list=PLa01scHy0YEmg8trm421aYq4OtPD8u1SN

- See my config that contains this stuff at
  https://github.com/mcdonc/.nixconfig/tree/use-plasma-manager

Overview
--------

- ``plasma-manager`` (https://github.com/pjones/plasma-manager) provides Home
  Manager modules which allow you to configure KDE Plasma using Nix.

- The configuration I presents here assumes:

  - You're using NixOS.

  - You're using a flake within ``/etc/nixos`` and your NixOS setup is
    configured to allow the use of flakes.

  - You're using home-manager as a NixOS module.

  If any of the above is untrue, you'll need to adapt what I present here to
  your particular setup.

Demo
----

- We can scrape our current KDE Plasma config by running::

    nix run github:pjones/plasma-manager > ~/plasma_orig.nix

- This will spit out a huge Nix attribute set to stdout.

- Note that currently there is a small bug that may require you to move your
  ``~/.config/dolphinrc`` aside temporarily before being able to successfully
  run the ``nix run`` command against plasma-manager (see
  https://github.com/pjones/plasma-manager/issues/17).  If so, you'll get an
  error something like::

    ./rc2nix:126:in `block (2 levels) in parse': /home/nixos/.config/dolphinrc: setting outside of group: MenuBar=Disabled (RuntimeError)
        from ./rc2nix:115:in `each'
        from ./rc2nix:115:in `block in parse'
        from ./rc2nix:114:in `open'
        from ./rc2nix:114:in `parse'
        from ./rc2nix:180:in `block in run'
        from ./rc2nix:176:in `each'
        from ./rc2nix:176:in `run'
        from ./rc2nix:266:in `<main>'    

  If so, just delete the offending line from ``dolphinrc`` or temporarily
  rename ``~/.config/dolphinrc`` to ``~/.config/dolphinrc_aside`` and rerun the
  ``nix run`` command.

- The captured ``.nix`` file will be large, and contains TMI.  But it does
  get us going, and works well enough for the purposes of this video.  We're
  just going to add it, lightly modified, to our version controlled Nix
  configuration, and then cause it to be included in our configuration.

- Note that pjones' plasma-manager does not currently capture theming or
  appearance choices.  This is because KDE tends to put state information into
  config files, likely.

- But I've created a branch in a trivial fork that does at
  https://github.com/mcdonc/plasma-manager/tree/enable-look-and-feel-settings

  It will capture a setting from the ``kdeglobals`` file named
  ``LookAndFeelPackage`` which is stripped intentionally upstream, probably
  because it's technically unknown whether or not the named theme is installed.
  But I always use one of the default themes, so I know it will be there::

        "kdeglobals"."KDE"."LookAndFeelPackage" = "org.kde.breezedark.desktop";

  It also includes settings from a file that pjones' upstream doesnt:
  ``~/.config/plasma-org.kde.plasma.desktop-appletsrc``, which contains info
  about which apps and widgets are in the task manager panel, which widgets I
  have on my desktop, and various other appearance-related settings.

  It *doesn't* yet capture which wallpaper I want to use, which is
  mindbendingly frustrating. :)

  But in any case, what I am now running to capture my KDE config state is::

    nix run github:mcdonc/plasma-manager/enable-look-and-feel-settings
        
- Some hand-editing of the result of running the above has to be done.  This is
  not ideal.  In particular, we need to replace any hardcoded paths in the
  output with expressions that will generate the right paths.  For me, a lot of
  these paths are wallpaper paths.

  I also want to be able to just select a wallpaper without needing to upload
  it, so I put a couple of them into the store and refer to them later in the
  config::

    { pkgs, plasma-manager, ...}:
    let
      wallpaper-large = builtins.path {
        path = ./a-scanner-darkly-desktop-wallpaper.jpg;
      };
      wallpaper-small = builtins.path {
        path = ./scannerdarkly.png;
      };
  
    imports = [
      plasma-manager.homeManagerModules.plasma-manager
    ];

    ... the path-fixed output from nix run ...

- Show a diff of the path-fixed output from nix run.

  I think it might technically be possible to have the script that runs when
  you do ``nix run`` replace a hardcoded path for any file that is present in
  the output that starts with ``/nix/store`` with an expression that resolves
  to the actual path in the nix store.  It just doesn't yet, so you gotta do it
  by hand.

- Demonstrate using ``nixos-rebuild build-vm``.
