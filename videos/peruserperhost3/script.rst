==========================================================================
NixOS 81: Flakes + Home Manager Multiuser/Multihost Configuration (Part 3)
==========================================================================

- Companion to video at

- This text script available via link in the video description.

- See the other videos in this series by visiting the playlist at
  https://www.youtube.com/playlist?list=PLa01scHy0YEmg8trm421aYq4OtPD8u1SN

Script
======

A little housekeeping before we start: my friend `Hynek
https://www.youtube.com/@The_Hynek`_ recently started a YouTube channel, and if
you like Python stuff, you should go check him out.  He will soon crush me in
YouTube ratings because he is completely shameless, but I have a few more
subsribers than he does, at least for the next few weeks, so this is kinda
really the only time I can promote him before he goes Mister-Beast and
forces me to appear in an endurance episode against other old people.  A
link to his channel will be in the description.

On to business.  This is part 3, and the final part, of a series of videos
about flakes and home manager.  It kinda presumes you've watched `part 1
<https://youtu.be/e8vzW5Y8Gzg>`_ and `part 2
<https://www.youtube.com/watch?v=CA8V2hEIxCc&t=79s>`_.  In those videos, we
shared OS-level configuration between systems, and we shared user-level
configuration between users.  Now we're really getting into the weeds, trying
to do home-manager configuration only for one user on one system, and not on
any other system.  It's getting pretty steamy in here.

By the way, if you want more basic context about NixOS flakes, I'd suggest you
watch `a video I made about flakes out of the box
<https://www.youtube.com/watch?v=hoB0pHZ0fpI>`_.  Links will be available in
the description.

In `part 1 of this series <https://youtu.be/e8vzW5Y8Gzg>`_ I created a
flake-based NixOS configuration that is can configure three different hosts and
I pushed it up to GitHub at https://github.com/mcdonc/peruserperhost .  In
`part 2 of this series <https://www.youtube.com/watch?v=CA8V2hEIxCc&t=79s>`_ I
added some home-manager configuration into the mix for two users, ``alice`` and
``bob``.  As it stands, all hosts share a common set of globally-available
programs and services but one of them runs a Postgres service that the others
don't.  ``alice`` has access to all three systems, ``bob`` has access to only
one of them.

Here's what is left to do:

- we want ``host2`` to have special home-manager configuration for the
  ``alice`` user; in particular, it should run a *user-level* systemd service
  as ``alice``.

- we want ``host3`` to have special home-manager configuration for the ``bob``
  user; it should add an additional shell alias for bob that isn't shared by
  ``alice``, but this alias shouldn't be in Bob's environment on ``host1``
  or ``host``, only on ``host3``.

Alice's ``host1`` Systemd Service
---------------------------------

We want to run a simple HTTP server as the ``alice`` user on ``host2`` using a
systemd user service.  The HTTP server will let anyone display/download files
from its ``/etc/nixos`` directory.

We'll add this within ``/etc/nixos/host1.nix`` .

.. code-block:: nix

    home-manager.users.alice = {

      systemd.user.services.show-nixconfig = {
        Unit = {
          Description = ''
            Run an HTTP server that displays the content of /etc/nixos on host2
          '';
        };
        Service = {
          Type = "simple";
          ExecStart = ''
            ${pkgs.python311}/bin/python -m http.server -d /etc/nixos 6543
          '';
        };
        Install = {
          WantedBy = [ "default.target" ];
        };
      };

    };

And rebuild.

Testing it:

- SSH in as Alice: ``ssh alice@192.168.1.128`` (can't su due to dbus)

- ``systemctl --user status show-nixconfig``

- ``nix profile install nixpkgs#inetutils``

- ``telnet localhost 6543``

This service will only run on ``host1``, not on ``host2`` or ``host3``.  The
code for ``home-manager.users.alice.systemd.user.services.show-nixconfig`` was
merged into Alice's other configuration in ``alice.nix`` and respected when we
rebuilt.

Commit and push when it works.
  
Creating Bob-Specific Shell Aliases Only on ``host3``
-----------------------------------------------------

We want ``host3`` to have special home-manager configuration for the ``bob``
user; it should add an additional shell alias for Bob that isn't shared by
``alice`` or any other user, but this alias shouldn't be in Bob's environment
on ``host1`` or ``host``, it should only be on ``host3``.

To get there, we'll add this code to ``host3.nix`` :

.. code-block:: nix

    home-manager.users.bob = {
      programs.bash.shellAliases = {
          latr = "${pkgs.coreutils}/bin/ls -latr";
      };
    };
   
Try to rebuild.  Once the rebuild works, log into ``host3`` do ``su - bob`` and
see that running ``latr`` as ``bob`` produces the right output and ``type
latr`` tells us it's a shell alias.

Note that ``alice`` doesn't hace access to this shell alias.  And if ``bob``
had an account on another machine, he would not have the ``latr`` alias on that
machine.  It is only on ``host3`` and only ``bob`` that has the ``latr`` alias.

Note also that ``bob`` can still invoke the ``ll`` shell alias defined within
``home.nix``, shared between ``bob`` and ``alice``.  Redefining it via our new
code in ``host3` doesn't override the ``ll`` shell alias defined in
``home.nix`` and imported via ``bob.nix``.  Instead, Nix attempts to merge all
attribute sets imported that resolve to
``home-manager.users.bob.programs.bash.shellAliases``.  There are no conflicts,
so it merges fine.

We can commit and push when it all works.

Conclusion
----------

If you've followed this dumb series of videos, thank you.  If it helped you,
let me know.  Personally, I think the way NixOS handles multihost+multiuser
centralized configuration is the bomb.  I absolutely loathe the Nix language
sometimes because it can be quirky and opaque, but I think the end result it
gives you when used with NixOS is terrific, not in small part due to the
features I've covered in this series.  It's insanely useful.

I would find it pretty difficult to use a different operating system at this
point.  I actually fired up Ubuntu the other day to diagnose some graphics
driver thing, and no matter what I did, Nvidia graphics would not work.  I
apt-installed apt-purged apt-repositoried, I apted a lot.  I'm a pretty
tenacious troubleshooter and I was defeated.  I reinstalled Ubuntu, and it
worked, of course.  This is not lack of experience: I used Ubuntu for almost 20
years before I started using NixOS.  And I've been using Linux for almost 30.

The experience I had with Ubuntu the other day is just not an experience I have
had so far with NixOS after using it for almost two years.  Things break, but
there is always a reason, and a more or less reasonable way to fix them that
doesn't involve leaving droppings all over the filesystem as you burrow your
way into the problem trying to find a solution.  I was reminded that as much as
I often curse Nix the language, I hate configuring systems by-hand even more.
