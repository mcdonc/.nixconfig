NixOS 57: Speedtesting Your Internet Connection Over Time
=========================================================

- Companion to video at

- This text script available via link in the video description.

- See the other videos in this series by visiting the playlist at
  https://www.youtube.com/playlist?list=PLa01scHy0YEmg8trm421aYq4OtPD8u1SN

Script
------

- I had a problem recently where my internet connection speed would vary
  randomly between 20Mbps up to 700Mbps.  I have a gigabit internet connection
  in theory.  There did not seem to be a pattern.

- I think I solved it by replacing both my router and my cable modem, but, for
  good measure, I'm going to try to keep an eye on it by recording historical
  speeds over time.

- I tried using ``speedtest-cli`` (a Python program) which uses Speedtest.net
  but it was flaky, commonly erroring.

- With some regrets, I fell back to using a CLI program that uses Netflix'
  Fast.net to test speed.  With the revocation of net neutrality, I'm not
  sanguine about the veracity of these reports, but it's the best I can manage
  right now, and it has indeed caught times when my connection speed is
  absurdly low.

- The ``fast-cli`` NixOS package provides a ``fast`` command that measures
  download speed.  It can also output JSON.  Demo it via ``fast --json|grep -v
  userIp``.

- I could have just outputted the JSON and appended it to a file, but I decided
  to write a small Python program that ran ``fast-cli --json``, parsed the
  output, and appended a row to a CSV file instead for ease of reading later.

- I called this ``fastlog.py`` (see
  https://github.com/mcdonc/.nixconfig/blob/master/etc/fastlog.py).

- It basically runs ``fast --json``, captures its output, parses the JSON, and
  appends a line to a CSV file with the time, the speed, the latency, and some
  other various things.

- Then I set up a Nix derivation that enables me to run the script, and a
  systemd timer that runs the script every four hours::

    let
      fastlog = pkgs.stdenv.mkDerivation {
        name = "fastlog";
        dontUnpack = true;
        installPhase = "install -Dm755 ${../etc/fastlog.py} $out/bin/fastlog";
      };
    in
      systemd.services.speedtest = {
        serviceConfig.Type = "oneshot";
        path = with pkgs; [ fastlog fast-cli python311 ];
        script = ''
          #!/bin/sh
          fastlog
        '';
      };

      systemd.timers.speedtest = {
        wantedBy = [ "timers.target" ];
        partOf = [ "speedtest.service" ];
        timerConfig = {
          # every four hours
          OnCalendar = "*-*-* 00,04,08,12,16,20:00:00";
          Unit = "speedtest.service";
        };
      };

- Now, every four hours an entry is written to ``/var/log/fast.csv`` that
  includes the download speed and a timestamp.  Demonstrate manually.
  
