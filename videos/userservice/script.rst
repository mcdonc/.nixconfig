======================================
NixOS #78: NixOS Systemd User Services
======================================

Companion to video at ....

This text script available via link in the video description.

See the other videos in this series by visiting the playlist at
https://www.youtube.com/playlist?list=PLa01scHy0YEmg8trm421aYq4OtPD8u1SN

Requisites
==========

The `home-manager <https://github.com/nix-community/home-manager>`_ NixOS
integration provides a mechanism to define `systemd user services
<https://wiki.archlinux.org/title/Systemd/User>`_ .  Systemd user services are
services that run as a normal user, rather than the root user, although they
are still managed by systemd.

I never bothered to use this feature on non-Nix systems, it just seemed like
too little gain for too much effort.  But in Nix, it feels like it's worth it,
because the configuration is pretty simple, it's captured and replayable, and
it's sharable between systems.

This feature works on NixOS and on non-NixOS systems that run systemd (like
Ubuntu) with Nix installed.


Running A Program Every So Often
================================

Let's say you want to be able to search for the packages that own a particular
file via the lovely `nix-index <https://github.com/nix-community/nix-index>`_
utiliity.  ``nix-index`` provides a command named ``nix-locate`` that, given a
filename, will return all of the derivations in your nix store that contain
that filename.

However, for ``nix-locate`` to work at all, you need to run the ``nix-index``
program, which creates a searchable database that ``nix-locate`` can work
against.  Furthermore, it's best to run ``nix-index`` every so often to reindex
the database, such that you can find files added to your Nix store over time.

We could just run ``nix-index`` every so often by hand, but we can also
automate things such that it runs every evening.  There is no need to run
``nix-index`` as root, it's perfectly willing to be run as a normal user.
This is a perfect job for systemd user services.

We need to define both a systemd user service and a systemd timer that runs the
service every so often.  ``home-manager`` can help us with this.

In your home-manager user's configuration, define
``systemd.user.service.nix-index`` and ``systemd.user.timers.nix-index``.

.. code-block:: nix

   systemd.user.services.nix-index = {
     Unit = {
       Description = "Run nix-index.";
     };
     Service = {
       Type = "oneshot";
       ExecStart = "${pkgs.nix-index}/bin/nix-index";
     };
     Install = {
       WantedBy = [ "default.target" ];
     };
   };

   # systemctl --user status nix-index.timer
   systemd.user.timers.nix-index = {
     Unit = {
       Description = "Timer for nix-index.";
     };
     Timer = {
       Unit = "nix-index.service";
       OnCalendar = "*-*-* 04:00:00";
     };
     Install = {
       WantedBy = [ "timers.target" ];
     };
   };

``systemd.user.services.nix-index`` is the service that actually runs
``nix-index``.  It is a `oneshot
<https://www.redhat.com/sysadmin/systemd-oneshot-service>`_ service, so it is
not expected to run as a daemon; it does its job and exits, and systemd is fine
with that.  Implicitly, it will be run as the user that is being defined by the
home-manager configuration (the ``home-manager.users.<user>`` user).  It will
run ``${pkgs.nix-index}/bin/nix-index``, as specified in its ``ExecStart``
parameter.

To actually invoke the service on a schedule, we need to set up a systemd user
timer unit, thus our definition of ``systemd.user.timers.nix-index``.  It
specifies ``nix-index.service`` as its ``Unit``, and its periodicity via
``OnCalendar`` (every day at 4AM).

And that's about it.

I use the NixOS integration of ``home-manager``, so I activate this
configuration via ``nixos-rebuild switch``.  Once I've done this, I can see the
status of both the service and of the timer using ``systemctl``::

  $ systemctl --user status nix-index.service
  ○ nix-index.service - Run nix-index.
       Loaded: loaded (/home/chrism/.config/systemd/user/nix-index.service; enabl>
       Active: inactive (dead) since Wed 2024-03-06 04:09:12 EST; 14h ago
  TriggeredBy: ● nix-index.timer
     Main PID: 498662 (code=exited, status=0/SUCCESS)
          CPU: 13min 57.400s

  Mar 06 04:04:10 optinix nix-index[498662]: [48.0K blob data]
  Mar 06 04:04:11 optinix nix-index[498662]: [48.0K blob data]
  Mar 06 04:04:11 optinix nix-index[498662]: [48.0K blob data]
  Mar 06 04:04:11 optinix nix-index[498662]: [48.0K blob data]
  Mar 06 04:04:12 optinix nix-index[498662]: [47.9K blob data]
  Mar 06 04:04:12 optinix nix-index[498662]: [48.0K blob data]
  Mar 06 04:04:12 optinix nix-index[498662]: [5.4K blob data]
  Mar 06 04:09:12 optinix nix-index[498662]: + wrote index of 62,873,219 bytes
  Mar 06 04:09:12 optinix systemd[2709]: Finished Run nix-index..
  Mar 06 04:09:12 optinix systemd[2709]: nix-index.service: Consumed 13min 57.400

  $ systemctl --user status nix-index.timer
  ● nix-index.timer - Timer for nix-index.
     Loaded: loaded (/home/chrism/.config/systemd/user/nix-index.timer; enabled>
     Active: active (waiting) since Sat 2024-03-02 18:00:48 EST; 4 days ago
    Trigger: Thu 2024-03-07 04:00:00 EST; 9h left
   Triggers: ● nix-index.service

   Mar 02 18:00:48 optinix systemd[2709]: Started Timer for nix-index..

If the timer doesn't show up as ``active`` you may need to do::

  $ systemctl --user start nix-index.timer

This won't be necessary after a reboot.

Running a Program as a Daemon
=============================

I have a self-written program which watches a directory for added media files
and transcodes them for use in my video editing workflow.  It's called
`watchintake
<https://github.com/mcdonc/.nixconfig/blob/master/bin/watchintake.py>`_ and
it's written in Python.  It uses inotifytools' `inotifywait
<https://linux.die.net/man/1/inotifywait>`_ command line tool to detect media
files added to the directory it's watching and that directory's subdirectories.
When it notices one, it causes that media file to be transcoded.

I can execute it by hand in the foreground by doing::

  $ watchintake /home/chrism/intake
  Beware: since -r was given, this may take a while!
  Watches established.

It will then run, transcoding files added to ``/home/chrism/intake`` forever or
at least until it reveals some error condition I haven't anticipated.

I've now set it up to run as a system user service:

.. code-block:: nix

   let
     watchintake = pkgs.substituteAll ({
       name = "watchintake";
       src = ../../bin/watchintake.py;
       dir = "/bin";
       isExecutable = true;
       py = "${pkgs.python311}/bin/python";
       inotifywait = "${pkgs.inotify-tools}/bin/inotifywait";
     });

   in {

     systemd.user.services.watchintake = {
       Unit = {
         Description = "Run watchintake.";
       };
       Service = {
         ExecStart = ''
           ${watchintake}/bin/watchintake ${homedir}/intake
         '';
       };
       Install = {
         WantedBy = [ "default.target" ];
       };
     };
   }

It's not a ``oneshot`` service (the default service type is ``simple``), and it
is therefore expected to run continuously; an exit is an error.  We can see its
status via ``systemctl``::

  $ systemctl --user status watchintake.service
  ● watchintake.service - Run watchintake.
       Loaded: loaded (/home/chrism/.config/systemd/user/watchintake.service; enabled; preset: enabled)
       Active: active (running) since Wed 2024-03-06 18:28:04 EST; 1s ago
     Main PID: 563111 (watchintake)
        Tasks: 2 (limit: 38263)
       Memory: 6.4M
          CPU: 65ms
       CGroup: /user.slice/user-1000.slice/user@1000.service/app.slice/watchintake.service
               ├─563111 /nix/store/yvhwsfbh4bc99vfvwpaa70m4yng4pvpz-python3-3.11.8/bin/python /nix/store/xk40w4bsvrvqq2ly0gai91f>
               └─563118 /nix/store/gasxhw4vmsv8nkn5m6j2gv5zcvj6rfdq-inotify-tools-4.23.9.0/bin/inotifywait -c -mr -eclose_write 

  Mar 06 18:28:04 optinix systemd[2709]: Started Run watchintake..
  Mar 06 18:28:04 optinix watchintake[563118]: Setting up watches.  Beware: since -r was given, this may take a while!
  Mar 06 18:28:04 optinix watchintake[563118]: Watches established.

If it's not already running, we can start it::

  $ systemctl --user start watchintake.service

And we can stop it::
  
  $ systemctl --user stop watchintake.service
  
In certain circumstances, it will likely be restarted automatically by systemd,
and it will always be started at system boot.

We can follow its output by doing::

  $ journalctl --user -u watchintake -f

If this doesn't work, you may need to reboot once, or use::

  $ journalctl --user -f
