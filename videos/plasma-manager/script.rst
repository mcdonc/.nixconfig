NixOS 51: Using Plasma-Manager to Configure Per-User Plasma Desktop Settings
============================================================================

- Companion to video at

- This text script available via link in the video description.

- See the other videos in this series by visiting the playlist at
  https://www.youtube.com/playlist?list=PLa01scHy0YEmg8trm421aYq4OtPD8u1SN

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

- We can scrape our current KDE Plasma config by running ``nix run github:pjones/plasma-manager``.

- This will spit out a huge Nix attribute set to stdout.

- We can capture it by running::

    nix run github:pjones/plasma-manager > ~/plasma_orig.nix

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

- The captured ``.nix`` file will be large, probably contains TMI.  But it does
  get us going, and works well enough for the purposes of this video.  We're
  just going to add it, lightly modified, to our version controlled Nix
  configuration, and then cause it to be included in our configuration.

- Note that pjones' plasma-manager does not currently capture theming or
  appearance choices.  This is because KDE tends to put state information into
  config files, likely.

- But I've created a branch in a fork that does at 

        "kdeglobals"."KDE"."LookAndFeelPackage" = "org.kde.breezedark.desktop";
        
  ruby rc2nix.rb -a ~/.config/plasma-org.kde.plasma.desktop-appletsrc
