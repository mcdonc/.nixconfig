==========================================
 NixOS 67: A Tour of My Nix Configuration
==========================================

- Companion to video at

- This text script available via link in the video description.

- See the other videos in this series by visiting the playlist at
  https://www.youtube.com/playlist?list=PLa01scHy0YEmg8trm421aYq4OtPD8u1SN

- See the full configuration with the features demonstrated at
  https://github.com/mcdonc/.nixconfig

Front Matter
============

This describes, at a high level, the NixOS configuration I've come up with over
the last year or so.  It is based on flakes.

It has undergone a level of factoring that you might call basic.

My ``/etc/nixos`` Tree
======================

The layout of my ``/etc/nixos`` directory looks something like::

  /etc/nixos
  ├── cachix
  │   ├── mcdonc.nix
  │   └── nixpkgs-python.nix
  ├── cachix.nix
  ├── common.nix
  ├── flake.lock
  ├── flake.nix
  ├── hosts
  │   ├── nixos-vm.nix
  │   ├── optinix.nix
  │   ├── profiles
  │   │   ├── backupsource
  │   │   │   └── default.nix
  │   │   ├── dnsovertls
  │   │   │   ├── resolvedonly.nix
  │   │   │   └── stubby.nix
  │   │   ├── encryptedzfs.nix
  │   │   ├── grub
  │   │   │   ├── alwaysnix.png
  │   │   │   ├── alwaysnix.xcf
  │   │   │   ├── btw.png
  │   │   │   ├── btw.xcf
  │   │   │   ├── efi.nix
  │   │   │   ├── orig.png
  │   │   │   ├── pepebtw.png
  │   │   │   ├── pepebtw.xcf
  │   │   │   └── pepe.jpg
  │   │   ├── macos-ventura.nix
  │   │   ├── nixindex.nix
  │   │   ├── oldnvidia.nix
  │   │   ├── pseries.nix
  │   │   ├── rc505
  │   │   │   ├── default.nix
  │   │   │   └── roland.patch
  │   │   ├── sessile.nix
  │   │   ├── speedtest
  │   │   │   ├── default.nix
  │   │   │   ├── fasthtml.py
  │   │   │   └── fastlog.py
  │   │   ├── steam.nix
  │   │   ├── tlp.nix
  │   │   └── tseries.nix
  │   ├── thinkcentre1.nix
  │   ├── thinknix420.nix
  │   ├── thinknix50.nix
  │   ├── thinknix512.nix
  │   ├── thinknix51.nix
  │   └── thinknix52.nix
  ├── prepsystem.sh
  ├── README.rst
  ├── users
     ├── chrism
     │   ├── a-scanner-darkly-desktop-wallpaper.jpg
     │   ├── config.nu
     │   ├── hm.nix
     │   ├── oh-my-posh.nu
     │   ├── plasma_before.nix
     │   ├── plasma.nix
     │   ├── scannerdarkly.png
     │   └── user.nix
     ├── keybase.nix
     ├── larry
     │   ├── hm.nix
     │   └── user.nix
        └── steam.desktop
 

``flake.nix``
=============

Inputs include ``nixpkgs``, ``nixpkgs-unstable``, ```nixos-hardware``,
``nix-gaming``, my own fork of ``nixpkgs``, and a variety of other github URLs.

In the outputs, I set up "modules" related to each of two users.  And I define
eight systems in ``nixosConfiguration``. In each one, choosing to use one or
the other set of user modules (or both)q as well as a host-specific config.

When ``nixos-rebuild`` is executed, the hostname on which it has been executed
is looked up in ``nixosConfigurations``, and the ``nixosSystem`` that it
matches is built.

All of my configuration for two users and eight systems is defined here.

Overlays
--------

In the outputs, I define an ``overlays`` function:

.. code-block:: nix

      overlays = (self: super: {
        steam = super.steam.override {
          extraProfile = "export STEAM_EXTRA_COMPAT_TOOLS_PATHS='${
              nix-gaming.packages.${system}.proton-ge
            }'";
        };
      });

And I use it later in each user module list:

.. code-block:: nix
      chris-modules = [
        ({ config, pkgs, ... }: { nixpkgs.overlays = [ overlays ]; })
      ];

This is a way to cause the default ``nixpkgs`` I define (based on
``nixos-23.11``) to produce derivations slightly different than their defaults.
In my case, I want to be able to use the latest Glorious Eggroll Proton version
within Steam, so I pass the thing that creates the Steam derivation some "extra
profile".

``nixpkgs`` Forks/Branches
--------------------------

It's very useful to be able to fork ``nixpkgs`` and make slight changes to a
package and then use that version of ``nixpkgs`` as a separate input when an
overlay won't work.  I couldn't figure out how to use an overlay to do what I
wanted, so I forked nixpkgs to upgrade to the latest Keybase:

.. code-block:: nix

    nixpkgs-keybase-bumpversion.url =
      "github:mcdonc/nixpkgs/keybase-bumpversion";

And then in the outputs:

.. code-block:: nix

      specialArgs = {
        pkgs-keybase-bumpversion = import nixpkgs-keybase-bumpversion {
          inherit system;
          config.allowUnfree = true;
        };
      };

Passing along ``specialArgs`` to ``nixosSystem``:

.. code-block:: nix

        thinknix512 = nixpkgs.lib.nixosSystem {
          inherit system specialArgs;
          modules = chris-modules ++ [ ./hosts/thinknix512.nix ];
        };

I do a similar thing to get packages from the ``unstable`` Nix repository,
although of course that's not my fork, it's just a branch of ``nixpkgs``, but
Nix treats them the same.

User configuration and ``home-manager`` configuration
-----------------------------------------------------

System-wide user configuration is in ``users/chrism/user.nix``.  It defines
``users.users.chrism``; his groups and his SSH config.

This bit of hair configures home-manager for my user:

.. code-block:: nix

      chris-modules = [
        {
          home-manager = {
            useUserPackages = true;
            users.chrism = import ./users/chrism/hm.nix;
            extraSpecialArgs = specialArgs;
          };
        }
      ];
                
It is not in standalone mode; if I want to make changes to my
home-manager-controlled programs or dotfiles, I run ``nixos-rebuild switch``.

The home-manager config in ``users/chrism/hm.nix`` is long and complicated.
But it:

- configures Gnome Terminal the way I like it.

- does some SSH client configuration.

- configures my Emacs, git, and zsh.

- sets up other various dotfiles.

Hosts
=====

One of my host configurations is in ``hosts/thinknix512.nix``.

It configures the system named ``thinknix512`` as a Thinkpad P-Series laptop
that doesn't regularly move, that has an encrypted ZFS root, that uses
DNS-over-TLS as possible, with Steam, and a common set of packages.

Much of the configuration is done as a set of imports:

.. code-block:: nix

  imports = [
    "${nixos-hardware}/lenovo/thinkpad/p51"
    "${nixos-hardware}/common/pc/ssd"
    ./profiles/pseries.nix
    ./profiles/sessile.nix
    ./profiles/encryptedzfs.nix
    ./profiles/tlp.nix
    # targeting 535.129.03, 545.29.02 backlightrestore doesn't work
    ./profiles/oldnvidia.nix
    ./profiles/dnsovertls/resolvedonly.nix
    ./profiles/steam.nix
    ./profiles/nixindex.nix
    ../common.nix
  ];


``nixos-hardware``
------------------

``nixos-hardware`` is a repository that contains prechewed configuration for
lots of types of hardware (Thinkpads, Dell laptops, Pinebooks, etc).  I've used
it here to signify that my machine is a Thinkpad P51, which sets up all the
stupid Nvidia crap and makes the wireless work.  I've also used it to tell Nix
that there's an SSD in it, so it will do SSD TRIM every so often.

``common.nix``
--------------

This file contains Nix code that is shared between all systems.  Most
importantly, it contains the big list of ``environment.systemPackages`` that
I'd like to share across all machines.

Host-specific configuration
---------------------------

The ``thinknix512`` machine hosts my backups, so there is some host-specific
config about ``sanoid`` and ``syncoid`` which are components of a ZFS backup
system.

We also define a host-specific set of ``environment.systemPackages`` to support
these backup tools.  These will be merged into the ones in ``common.nix`` as
necessary.

Other hosts
-----------

Take a look at ``optinix.nix``.  It configures a Dell Optiplex small form
factor PC similar to ``thinknix512.nix`` but its configuration is simpler.

Factoring Host Roles
====================

Files exist in ``hosts/profiles`` that sorta contains "role-based"
configuration, used by each host.

Some of the roles that a host can play: a backup source (ZFS), a machine that
runs an internet speedtest every few hours, a machine that uses the
``nix-index`` system and updates its index every day, a system that is
DNS-over-TLS only (no unencrypted DNS), and others.

These are activated by including them in a host's ``imports`` list.

