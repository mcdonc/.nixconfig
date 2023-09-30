NixOS 56: NixOS vs Silverblue (or why NixOS both is and *isn't* an "immutable" distro
=====================================================================================

- Companion to video at

- This text script available via link in the video description.

- See the other videos in this series by visiting the playlist at
  https://www.youtube.com/playlist?list=PLa01scHy0YEmg8trm421aYq4OtPD8u1SN

Script
------

- If you're a frequent watcher of tech YouTube channels like me, it's hard to
  avoid videos about "immutable" Linux distributions like Fedora Silverblue,
  Vanilla OS, and Talos Linux.  NixOS and NixOS-like systems such as Guix are
  often lumped in with these.

- NixOS is indeed an "immutable" distribution, but its form of immutability is
  different than the other distros that are often mentioned in the same breath.

- NixOS is different from these other distributions because:

  - NixOS does not rely on application containerization for package management
    (e.g. Flatpak or Snap).  Applications run without containerization or
    chrooting. It *supports* Flatpaks and AppImages but does not require them,
    and most people who use NixOS really don't bother with them.

  - NixOS does not use the concept of an immutable base image created by an
    upstream entity which a large number of users share.  Its system packages
    are managed the same as its user packages.
  
  - The reason it can do these things: NixOS is not a Linux FHS-compliant
    distribution.  This means that it does not install software into a global
    namespace (e.g. overlaying an application into /etc, /bin, /usr, etc) like
    almost every other Linux distro; instead it installs each package into a
    separate directory inside its "store" at ``/nix/store``.

  - Being non-FHS-compliant has some non-trivial downsides, including
    incompatibility with binary-only packages shipped by third parties and the
    need to correct the assumptions about FHS-compatibility made by application
    developers when packaging something for NixOS natively.  This means many
    people that have the expectation that it's just "another Linux distro" will
    be disappointed; using it requires some understanding of how software is
    built, and a willingness to cope in various ways when non-native packages
    make incorrect assumptions about the environment (e.g. show tox.nix).

  - The upsides vs. e.g. Silverblue:

    - You needn't reboot when you update (unless you want to switch to a new
      kernel version).  This is because it doesn't use a sort of A/B boot
      system like ``rpm-ostree`` in Silverblue.  When you update, the changes
      are immediately available without a reboot.

    - Applications, rather than perhaps seeing a filesystem that is inside a
      container, see the root filesystem.  This can mean easier management for
      theming consistency, etc.

    - Multiple versions of the same application and its dependencies can exist
      on the system at the same time.  This is possible with Flatpak too, but
      in NixOS dependency sharing between a number of different versions of an
      application is common, whereas in Flatpak, each container kinda ships
      everything it depends upon within each package.  This can make auditing
      the system and remediating security issues tricky; it is not so tricky on
      NixOS, it's basically an "ls" of ``/nix/store``.

- The presumable reason that NixOS is lumped in with other immutable
  distribution is because ``/nix/store`` is immutable.  It is read-only to all
  but a single system service.  When you invoke certain commands, a package is
  added to the store by this system service, and it is only removed when a
  garbage collection process detects it no longer depended upon by anything the
  user cares about.  The downside of this is that disk space used is often
  quite high between runs of the garbage collector.

- The rest of the system is quite mutable, although files written by NixOS
  services and things like "home-manager" are typically read-only, and they are
  expected to not be changed by hand.  Instead they are expected to be managed
  by Nix itself.  But otherwise if you want to change something outside /var or
  /etc, you can knock yourself out in NixOS, it doesn't care.  It doesn't have
  weird rules about how update will either copy or not copy things from
  ``/etc`` from the old boot image, for example.

- Immutability in NixOS is required by its store design, but it isn't really a
  feature of NixOS that anyone who regularly uses it thinks about.  It just
  comes along for the ride.  The real killer features of NixOS are declarative
  configuration, shared configuration between systems, the ability to easily
  run ancient software on completely up-to-date systems, and fearless updates
  spanning multiple generations (not just two, ala ``rpm-ostree``).

- Calling NixOS an "immutable distro" I think gives people the wrong impression
  of its strengths and weaknesses.  For me, it is more attractive than any
  traditional FHS-compliant Linux distro, immutable or no.  For you, maybe not.

Demo 1
------

- Updating Silverblue.  (``rpm-ostree update``)

- Updating Nix.  (``nix flake update && nixos-rebuild switch``)

Demo 2
------

- Installing software on Silverblue. (all Flatpak, wind up in
  ``.local/share/flatpak`` and/or ``/var/lib/flatpak``)

- Installing software on Nix (wind up in ``/nix/store``).
  

  
