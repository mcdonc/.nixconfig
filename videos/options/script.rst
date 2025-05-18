NixOS 100: Defining and Using Custom NixOS Options
==================================================

- Companion to video at https://www.youtube.com/watch?v=Z5vyoBqYfuE
  
- See the other videos in this series by visiting the playlist at
  https://www.youtube.com/playlist?list=PLa01scHy0YEmg8trm421aYq4OtPD8u1SN

About
-----

I recently had to write my own fan control script for a rackmount server for
boring reasons.  It is at https://github.com/mcdonc/idracfanctl .

There is no reason to make it completely configurable via NixOS options, but
that's what we're going to do, cuz we don't need reasons.

The Fan Control Script
----------------------

The script, written in Python, takes various options for fan speed and thermals
via command line options like ``--temp-cpu-max`` and others.  It is meant to be
started early at system startup via systemd.

I currently have the following Nix which both packages the script to put it in
the Nix store, and creates a systemd service unit for it.  I do this within a
``idracfanctl.nix``:

.. code-block:: nix

   # idcracfanctl.nix

   { pkgs, lib, ...}:

   let

     # define a derivation for the script

     idracfanctl = pkgs.stdenv.mkDerivation {
       name="idracfanctl";
       src = pkgs.fetchFromGitHub {
         owner = "mcdonc";
         repo = "idracfanctl";
         rev = "f7393a7cfcd4b72d48567e4088f179f51790e9aa";
         sha256 = "sha256-pIp9sODUO78D3u8+c/JUA0BWH4V8M7Ohf+DvLE7X5vA=";
       };
       buildInputs = [
         pkgs.makeWrapper
       ];
       installPhase = ''
         mkdir -p $out/bin
         cp idracfanctl.py $out/bin/idracfanctl.py
         makeWrapper ${pkgs.python3.interpreter} $out/bin/idracfanctl \
           --add-flags "$out/bin/idracfanctl.py"
       '';
       meta = with lib; {
         description = "Dell PowerEdge R730xd fan control";
         homepage = "https://github.com/mcdonc/idracfanctl";
         license = licenses.mit;
         platforms = platforms.all;
       };
     };
   in

   {

     # start the script early at system startup

     systemd.services.idracfanctl = {
       description = "Control Dell R730xd fans";
       after = [ "local-fs.target" ];
       before = [ "multi-user.target" ];
       wantedBy = [ "multi-user.target" ];

       serviceConfig = {
         ExecStart = ''
           ${idracfanctl}/bin/idracfanctl --disable-pcie-cooling-response=1 \
             --ipmitool="${pkgs.ipmitool}/bin/ipmitool"
         '';
         Restart = "always";
         User = "root";
         KillSignal = "SIGINT";
       };
     };
   }

This NixOS module defines a derivation that grabs the software and then defines
and starts a systemd service using the software.

Let's run ``nixos-rebuild switch`` and see what it gives us.

When it's done, let's take a look at
``/etc/systemd/system/idracfanctl.service`` that Nix composed for us:

.. code-block:: ini

   [Unit]
   After=local-fs.target
   Before=multi-user.target
   Description=Control Dell R730xd fans

   [Service]
   Environment="LOCALE_ARCHIVE=/nix/store/0ip389clsbrbjmhmrysgfghqnhx8qlfd-glibc-locales-2.40-66/lib/locale/locale-archive"
   Environment="PATH=/nix/store/87fck6hm17chxjq7badb11mq036zbyv9-coreutils-9.7/bin:/nix/store/7y59hzi3svdj1xjddjn2k7km96pifcyl-findutils-4.10.0/bin:/nix/store/gqmr3gixlddz3667ba1iyqck3c0dkpvd-gnugrep-3.11/bin:/nix/store/clbb2cvigynr235ab5zgi18dyavznlk2-gnused-4.9/bin:/nix/store/if9z6wmzmb07j63c02mvfkhn1mw1w5p4-systemd-257.5/bin:/nix/store/87fck6hm17chxjq7badb11mq036zbyv9-coreutils-9.7/sbin:/nix/store/7y59hzi3svdj1xjddjn2k7km96pifcyl-findutils-4.10.0/sbin:/nix/store/gqmr3gixlddz3667ba1iyqck3c0dkpvd-gnugrep-3.11/sbin:/nix/store/clbb2cvigynr235ab5zgi18dyavznlk2-gnused-4.9/sbin:/nix/store/if9z6wmzmb07j63c02mvfkhn1mw1w5p4-systemd-257.5/sbin"
   Environment="TZDIR=/nix/store/qyihkwbhd70ynz380whj3bsxk1d2lyc4-tzdata-2025b/share/zoneinfo"
   ExecStart=/nix/store/df10anlm8zn6h0p45q42gn2qgzdcf2nq-idracfanctl/bin/idracfanctl --disable-pcie-cooling-response=1 \
     --ipmitool="/nix/store/r5g6csjbwnfzi20s5kq6m0j6chd13a6l-ipmitool-1.8.19-unstable-2025-02-18/bin/ipmitool"

   KillSignal=SIGINT
   Restart=always
   User=root
   
   [Install]
   WantedBy=multi-user.target

We can see the service has been started via ``systemctl status
idracfanctl.service``.

That's pretty much all I personally need right now.  I use the defaults for
all of the values save for ``--disable-pcie-cooling-response`` and
``--ipmitool``.

But the defaults won't be suitable for everyone.  If someone else wanted to use
the script under NixOS, they'd need to edit the
``systemd.services.idracfanctl.serviceConfig.ExecStart`` value to pass in extra
options.  And if *I* had another shitty rackmount server in a different
location that needed this functionality, but needed different values, I'd have
to do that too, and I'd have to fork the module, keeping one fork for each
server.

We can give them (and ourselves) a nicer, value-checked way, more reusable way
to do this by defining NixOS options for our service and using them.

Let's convert ``idracfanctl.nix`` to define those options:

.. code-block:: nix

   { pkgs, lib, config, ... }:

   {
     options.services.idracfanctl = {
       enable = lib.mkOption {
         type = lib.types.bool;
         description = "Enable the idracfanctl service";
         default = true;
       };
       ipmitool = lib.mkOption {
         type = lib.types.package;
         default = pkgs.ipmitool;
         defaultText = lib.literalExpression "pkgs.ipmitool";
         description = "The ipmitool package to use";
       };
       temp-cpu-min = lib.mkOption {
         type = lib.types.int;
         default = 45;
         description = ''
           Script won't adjust fans from fan-percent-min til temp-cpu-min
           in °C is reached.
         '';
       };
       temp-cpu-max = lib.mkOption {
         type = lib.types.int;
         default = 96;
         description = ''
           Max CPU temp in °C that should be allowed before revert to Dell
           dynamic fan control."
         '';
       };
       temp-exhaust-max = lib.mkOption {
         type = lib.types.int;
         default = 65;
         description = ''
           When exhaust temp reaches this value in °C, revert to Dell
           dynamic fan control.
         '';
       };
       fan-percent-min = lib.mkOption {
         type = lib.types.int;
         default = 13;
         description = ''
           The minimum percentage that the fans should run at when under
           script control.
         '';
       };
       fan-percent-max = lib.mkOption {
         type = lib.types.int;
         default = 63;
         description = ''
           The maxmum percentage that the fans should run at when under
           script control.
         '';
       };
       fan-step = lib.mkOption {
         type = lib.types.int;
         default = 2;
         description = ''
           The number of percentage points to step the fan curve by.
         '';
       };
       hysteresis = lib.mkOption {
         type = lib.types.int;
         default = 2;
         description = ''
           Don't change fan speed unless the temp difference in °C exceeds
           this number of degrees since the last fan speed change.
         '';
       };
       sleep = lib.mkOption {
         type = lib.types.int;
         default = 10;
         description = ''
           The number of seconds between attempts to readjust the fan speed
           the script will wait within the main loop.
         '';
       };
       disable-pcie-cooling-response = lib.mkOption {
         type = lib.types.bool;
         default = false;
         description = ''
           If false, use the default Dell PCIe cooling response, otherwise
           rely on this script to do the cooling even for PCIe cards that
           may not have fans.  NB: changes IPMI settings.
         '';
       };

     };
     config =
       let
         cfg = config.services.idracfanctl;
         idracfanctl = pkgs.stdenv.mkDerivation {
           name = "idracfanctl";
           src = pkgs.fetchFromGitHub {
             owner = "mcdonc";
             repo = "idracfanctl";
             rev = "f7393a7cfcd4b72d48567e4088f179f51790e9aa";
             sha256 = "sha256-pIp9sODUO78D3u8+c/JUA0BWH4V8M7Ohf+DvLE7X5vA=";
           };
           buildInputs = [
             pkgs.makeWrapper
           ];
           installPhase = ''
             mkdir -p $out/bin
             cp idracfanctl.py $out/bin/idracfanctl.py
             makeWrapper ${pkgs.python3.interpreter} $out/bin/idracfanctl \
               --add-flags "$out/bin/idracfanctl.py"
           '';
           meta = with lib; {
             description = "Dell PowerEdge R730xd fan control";
             homepage = "https://github.com/mcdonc/idracfanctl";
             license = licenses.mit;
             platforms = platforms.all;

           };
         };
         execstart = ''${idracfanctl}/bin/idracfanctl \
     --disable-pcie-cooling-response=${if cfg.disable-pcie-cooling-response then "1" else "0"} \
     --ipmitool="${cfg.ipmitool}/bin/ipmitool" \
     --temp-cpu-min=${toString cfg.temp-cpu-min} \
     --temp-cpu-max=${toString cfg.temp-cpu-max} \
     --temp-exhaust-max=${toString cfg.temp-exhaust-max} \
     --fan-percent-min=${toString cfg.fan-percent-min} \
     --fan-percent-max=${toString cfg.fan-percent-max} \
     --fan-step=${toString cfg.fan-step} \
     --hysteresis=${toString cfg.hysteresis} \
     --sleep=${toString cfg.sleep}'';
       in
       lib.mkIf cfg.enable {
         systemd.services.idracfanctl = {
           description = "Control Dell R730xd fans";
           after = [ "local-fs.target" ];
           before = [ "multi-user.target" ];
           wantedBy = [ "multi-user.target" ];

           serviceConfig = {
             ExecStart = "${execstart}";
             Restart = "always";
             User = "root";
             KillSignal = "SIGINT";
           };
         };
       };
   }

We are defining two top-level attribute sets here: ``options`` and ``config``.

The attribute set implied by ``options.services.idracfanctl`` define the
allowed values, and the ``config`` interprets those values and uses lower-level
options to turn our values into a ``systemd.services.idracfanctl`` service,
which NixOS will run for us, as long as our service is enabled (as long as
``services.idracfanctl.enable`` is true).

Our options have:

- a name e.g. ``enable`` or ``ipmitool``, which is the name that people use to
  maniuplate the option within ``services.idracfanctl``.

- a type e.g. ``types.bool`` or ``types.package`` which tells Nix how to
  validate and evaluate and resolve the value that people give it.  There are
  many options types, we only use a few.

- a default value.

- a description.

``cfg`` defined inside the ``config =`` let block will be the *evaluated*
configuration values within ``services.idracfanctl`` that our user defined
options for.  It pulls these from ``config.services.idracfanctl``.

I know there's a lot of ``configs`` here, it's not ideal, and I realize it's
hard to disambiguate them.  Think of ``config.services.idracfanctl`` pulling
``services.idracfanctl`` from the value named ``config`` passed to us within
the function definition at the top.  That namespace is magically populated by
the values supplied to our options to prepare it for evaluation in the
``config=`` block of our module.  There's some Nix lazy magic happening here,
but please try to roll with it.

Note that our original script could have been written like this:

.. code-block:: nix

   { pkgs, lib, ...}:

   let
     idracfanctl = pkgs.stdenv.mkDerivation {
       name="idracfanctl";
       src = pkgs.fetchFromGitHub {
         owner = "mcdonc";
         repo = "idracfanctl";
         rev = "f7393a7cfcd4b72d48567e4088f179f51790e9aa";
         sha256 = "sha256-pIp9sODUO78D3u8+c/JUA0BWH4V8M7Ohf+DvLE7X5vA=";
       };
       buildInputs = [
         pkgs.makeWrapper
       ];
       installPhase = ''
         mkdir -p $out/bin
         cp idracfanctl.py $out/bin/idracfanctl.py
         makeWrapper ${pkgs.python3.interpreter} $out/bin/idracfanctl \
           --add-flags "$out/bin/idracfanctl.py"
       '';
       meta = with lib; {
         description = "Dell PowerEdge R730xd fan control";
         homepage = "https://github.com/mcdonc/idracfanctl";
         license = licenses.mit;
         platforms = platforms.all;
       };
     };
   in

   {
     config = {
       systemd.services.idracfanctl = {
         description = "Control Dell R730xd fans";
         after = [ "local-fs.target" ];
         before = [ "multi-user.target" ];
         wantedBy = [ "multi-user.target" ];
         
         serviceConfig = {
           ExecStart = ''
             ${idracfanctl}/bin/idracfanctl --disable-pcie-cooling-response=1 \
               --ipmitool="${pkgs.ipmitool}/bin/ipmitool"
           '';
           Restart = "always";
           User = "root";
           KillSignal = "SIGINT";
         };
       };
     };
  }

Note the extra ``config= {`` surrounding our actual configuration options like
``systemd.services.idracfanctl``.  Allowing for its omission is just a nicety
for people who aren't using options.

Let's run ``nixos-rebuild switch`` and take a look at
``/etc/systemd/system/idracfanctl.service``:

.. code-block:: ini

   [Unit]
   After=local-fs.target
   Before=multi-user.target
   Description=Control Dell R730xd fans

   [Service]
   Environment="LOCALE_ARCHIVE=/nix/store/0ip389clsbrbjmhmrysgfghqnhx8qlfd-glibc-locales-2.40-66/lib/locale/locale-archive"
   Environment="PATH=/nix/store/87fck6hm17chxjq7badb11mq036zbyv9-coreutils-9.7/bin:/nix/store/7y59hzi3svdj1xjddjn2k7km96pifcyl-findutils-4.10.0/bin:/nix/store/gqmr3gixlddz3667ba1iyqck3c0dkpvd-gnugrep-3.11/bin:/nix/store/clbb2cvigynr235ab5zgi18dyavznlk2-gnused-4.9/bin:/nix/store/if9z6wmzmb07j63c02mvfkhn1mw1w5p4-systemd-257.5/bin:/nix/store/87fck6hm17chxjq7badb11mq036zbyv9-coreutils-9.7/sbin:/nix/store/7y59hzi3svdj1xjddjn2k7km96pifcyl-findutils-4.10.0/sbin:/nix/store/gqmr3gixlddz3667ba1iyqck3c0dkpvd-gnugrep-3.11/sbin:/nix/store/clbb2cvigynr235ab5zgi18dyavznlk2-gnused-4.9/sbin:/nix/store/if9z6wmzmb07j63c02mvfkhn1mw1w5p4-systemd-257.5/sbin"
   Environment="TZDIR=/nix/store/qyihkwbhd70ynz380whj3bsxk1d2lyc4-tzdata-2025b/share/zoneinfo"
   ExecStart=/nix/store/df10anlm8zn6h0p45q42gn2qgzdcf2nq-idracfanctl/bin/idracfanctl \
     --disable-pcie-cooling-response=0 \
     --ipmitool="/nix/store/r5g6csjbwnfzi20s5kq6m0j6chd13a6l-ipmitool-1.8.19-unstable-2025-02-18/bin/ipmitool" \
     --temp-cpu-min=45 \
     --temp-cpu-max=96 \
     --temp-exhaust-max=65 \
     --fan-percent-min=13 \
     --fan-percent-max=63 \
     --fan-step=2 \
     --hysteresis=2 \
     --sleep=10
   KillSignal=SIGINT
   Restart=always
   User=root

Unlike before, where the a mere ``import`` would start the ``idracfanctl``
service, we now need to define at least ``services.idracfanctl.enable = true;``
somewhere in our NixOS configuration for the service to start.

We can change the minimum fan speed via
``services.idracfanctl.fan-percent-min = 50;``

We can try to inject nonsensical values into our service, they won't work.

How do people find out which options our service offers and what they mean?
Most NixOS options usable in your configuration can be found via
``nixos-options`` e.g. ``nixos-options services.idracfanctl``, at least once
you've installed the modules that provide the options.

Followup
--------

Maybe in a followup video, I'll describe how to package this module as a flake
to allow you to distribute to others for easy use.

