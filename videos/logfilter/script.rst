NixOS 44: Filtering Systemd Log Messages on NixOS 23.05
=======================================================

- Companion to video at

- See the other videos in this series by visiting the playlist at
  https://www.youtube.com/playlist?list=PLa01scHy0YEmg8trm421aYq4OtPD8u1SN

Video Script
------------

- Systemd v253+ (which is present in NixOS 23.05+, but no earlier NixOS) allows
  you to filter log messages emanating from a service using the
  ``LogFilterPatterns`` directive in the service's configuration.  See
  https://www.freedesktop.org/software/systemd/man/systemd.exec.html (search
  for ``LogFilterPatterns``).  In particular, any pattern that begins with
  ``~`` is filtered out.

- In NixOS, you can use ``systemd.services.<servicename>.serviceConfig`` to add
  a ``LogFilterPatterns`` matching the body of the offending messages coming
  from the service, and they will be filtered out. It should be a string which
  starts with the tilde and then a regular expression matching the messages
  you'd like to filter out::

   #"Jun 19 13:00:01 thinknix512 cupsd[2350]: Expiring subscriptions..."  
   systemd.services.cups = {
     overrideStrategy = "asDropin";
     serviceConfig.LogFilterPatterns="~.*Expiring subscriptions.*";
   };
    
- This will cause ``/etc/systemd/system/cups.service.d/overrides.conf`` to
  contain the line::
    
    LogFilterPatterns=~.*Expiring subscriptions.*
  
