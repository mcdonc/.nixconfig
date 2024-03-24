=======================================================================
NixOS 82: Upgrading a NixOS Service (Pipewire) To Unstable Using Flakes
=======================================================================

Companion to video at ....

This text script available via link in the video description.

See the other videos in this series by visiting the playlist at
https://www.youtube.com/playlist?list=PLa01scHy0YEmg8trm421aYq4OtPD8u1SN

Script
------

NixOS "services" are components of the operating system that encapsulate build
information about software, information about how to start and stop process
related to that software, information about how to manage configuration files
related to that software, and other OS tweaks such as new ``udev`` rules that
must be in place for the software to run properly.  They are usually configured
in NixOS via a ``services.<foo>`` attribute set.  The options within the
attribute set related to a service differ per-service.

One of the services that can be configured in NixOS is Pipewire.  NixOS, by
default, uses Pipewire for audio playback and recording.  Pipewire is a complex
piece of software.  It can emulate the API of the three major Linux standards
for interfacing audio software to hardware: ALSA, PulseAudio, and JACK.  So
it's bound to have bugs.

What if we run into a bug in the version of Pipewire that is shipped with a
stable version of NixOS (23.11 as of this writing)?  It would sure be nice if
we could upgrade it easily to a newer version that doesn't have the issue we've
run into.

Now, I made a video a while back entitled `Mixing Older and Newer nixpkgs
Packages Under a Flakes-based Config <https://youtu.be/0NbSw1RwPow>`_ . It
described how to use some software from ``nixos-unstable`` within an install
that is otherwise based on a stable NixOS release.  But it didn't cover
*services*.  The video is useful if you want to know how to start using a newer
version of, for example, an application that has some finite start and end time
controlled by a user, like, say OBS Studio.  But Pipewire isn't just an
application that a normal user starts up and shut down.  It is a set of things
including instructions for starting a set of processes at boot time and user
login time, a set of rules about configuration file composition and placement,
a set of ``udev`` rules, and various API surfaces that other applications talk
to during their own shorter lifetimes.  It's more than an application, it's,
well..  a *service*.

To demonstrate how we might work around a theoretical bug in some release of
Pipewire that we're stuck with because we're on a stable version of NixOS,
let's try to use the version of Pipewire from ``nixos-unstable`` instead.  I'm
going to assume you're already using Nix flakes, and it will assume you've used
them for more than, let's say, 20 minutes.  If you aren't, and you haven't,
apologies, but you might take a look at a couple of my older videos that tell
you how and why you might want to start using them to configure NixOS: `NixOS
40: Converting an Existing NixOS Configuration To Flakes
<https://youtu.be/Hox4wByw5pY>`_ and `NixOS 63: Install NixOS 23.11 and Use
Flakes Out Of the Box <https://youtu.be/hoB0pHZ0fpI>`_ ,.

Be warned that this method doesn't work for *every* NixOS service, but it does
for many of them.  And it definitely works for Pipewire.

Details
-------

The NixOS Pipewire service is configured via settings within the
``services.pipewire`` attribute set.  This is the default ``services.pipewire``
attribute set that the NixOS installer producers for Pipewire configuration.

.. code-block:: nix

    services.pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
    };

For the record, you can also tell Pipewire to also emulate Jack by adding:

.. code-block:: nix

    services.pipewire = {
      jack.enable = true;
    };

There are a number of other sound-related settings in the default
``configuration.nix`` supplied by the NixOS installer:

.. code-block:: nix

   sound.enable = true;
   hardware.pulseaudio.enable = false;
   security.rtkit.enable = true;

For the record, none of these impact Pipewire service
configuration. ``sound.enable = true`` is only respected by PulseAudio, not
Pipewire.  And of course, enabling PulseAudio and Pipewire simultaneousy would
likely have hilarious results unless you know exactly what you're doing.  And
if you're concerned about audio processing latency, you'll want to enable
``security.rtkit``.  But we can otherwise ignore these for now.

I'm going to presume we're configuring a system that is set up with a NixOS
flake that is running NixOS 23.11 (aka ``github:NixOS/nixpkgs/nixos-23.11``).
We will reuse the the tricks we used in `Mixing Older and Newer nixpkgs
Packages Under a Flakes-based Config <https://youtu.be/0NbSw1RwPow>`_ to add an
additional input for NixOS unstable (ala
``github:NixOS/nixpkgs/nixos-unstable``) to our ``flake.nix``.

Before:

.. code-block:: nix

    {

    description = "My flakes configuration";

    inputs = {
      nixpkgs.url = "github:NixOS/nixpkgs/nixos-23.11";
    };

    outputs = { self, nixpkgs }@inputs:
    let
      system = "x86_64-linux";
      specialArgs = inputs // { inherit system; };
    in {
        nixosConfigurations = {
          host1 = nixpkgs.lib.nixosSystem {
            specialArgs = specialArgs;
            system = system;
            modules = [ ./configuration.nix ];
          };
        };
      };
    }

After:

.. code-block:: nix

    {

    description = "My flakes configuration";

    inputs = {
      nixpkgs.url = "github:NixOS/nixpkgs/nixos-23.11";
      nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    };

    outputs = { self, nixpkgs, nixpkgs-unstable }@inputs:
    let
      system = "x86_64-linux";
      specialArgs = inputs // { inherit system; };
    in {
        nixosConfigurations = {
          host1 = nixpkgs.lib.nixosSystem {
            specialArgs = specialArgs;
            system = system;
            modules = [ ./configuration.nix ];
          };
        };
      };
    }

We added ``nixpkgs-unstable.url`` as an input.  We also added
``nixpkgs-unstable`` to the argument list we feed into the outputs.

Now we also have to make changes to ``configuration.nix`` which is included
from ``flake.nix``.

Here are the relevant portions of ``configuration.nix`` before we make our
changes:

.. code-block:: nix

    { config, pkgs, lib, ... }:

    {
      # .. other elided config ..
      services.pipewire = {
        enable = true;
        alsa.enable = true;
        alsa.support32Bit = true;
        pulse.enable = true;
        jack.enable = true;
      };
    }
    
The relevant portions of ``configuration.nix`` after:

.. code-block:: nix

    { config, pkgs, lib, nixpkgs-unstable, system, ... }:

    let
        pkgs-unstable = import nixpkgs-unstable {
          inherit system;
          config.allowUnfree = true;
        };
    in

    {

      # .. other elided config ..
      services.pipewire = {
        package = pkgs-unstable.pipewire;
        enable = true;
        alsa.enable = true;
        alsa.support32Bit = true;
        pulse.enable = true;
        jack.enable = true;
      };

    }


We've added ``nixpkgs-unstable`` and ``system`` to the ``configuration.nix``
argument list, and we've added a let-in statement which sets up
nixpkgs-unstable for us so we can later use it.  We then add ``package =
nixpkgs-unstable.pipewire`` to our ``services.pipewire`` attribute set.

I'm also going to add in some hair to our ``configuration.nix`` so we can
better see what the effect of running ``nixos-rebuild`` is after we've made
these changes.

.. code-block:: nix

    system.activationScripts.diff = {
      supportsDryActivation = true;
      text = ''
        ${pkgs.nvd}/bin/nvd --nix-bin-dir=${pkgs.nix}/bin diff \
             /run/current-system "$systemConfig"
      '';
    };

Let's note the output of ``pipewire --version`` before we rebuild the system::

 [chrism@host1:/etc/nixos]$ pipewire --version
 pipewire
 Compiled with libpipewire 1.0.1
 Linked with libpipewire 1.0.1

Rebuild.

The output of ``pipewire --version`` after we rebuild the system::

 [chrism@host1:/etc/nixos]$ pipewire --version
 pipewire
 Compiled with libpipewire 1.0.4
 Linked with libpipewire 1.0.4

Taking a look at the result of ``nixos-rebuild``, we see that it didn't just
upgrade the pipewire package itself.  It upgraded all the *dependencies* of
Pipewire too.  It added a number of dependencies (e.g. ``cracklib``,
``libcbor``) and added newer versions of dependency packages that already
existed on the system (e.g. ``alsa-lib``, ``libGL``, ``libvorbis``). Dozens of
them.

Some of these libraries just came along for the ride because they are the
version supplied by NixOS unstable, and the closure of dependencies just kinda
scooped them up into the mix because the closure of the dependencies is what
has been tested to work.  Pipewire 1.0.4 almost certainly doesn't actually need
a newer version of **bash** than Pipewire 1.0.1, for example.  But undoubtedly
some of them were upgraded because Pipewire 1.0.4 requires the newer version,
and all of the packages that were *added* were added because Pipewire 1.0.4
requires them.

Because Nix allows or more than one version of a library (or any package) to be
installed on the system at the same time, we are able to upgrade Pipewire and
its dozens of dependencies without concern that it will break other
applications on the system, and replace the *entire working Pipewire subsystem*
with another *entirely working Pipewire subsystem* by adding, effectively, one
line of configuration (``package = pkgs-unstable.pipewire``).

A Shout-Out to The Skeptical
----------------------------

"That's all well and good", you say.

"But ``nixpkgs-unstable.pipewire`` doesn't solve my problem!  The bug I've
encountered isn't fixed in a version of Pipewire packaged by NixOS.  The fix
hasn't even made it out to a Pipewire release yet, or it's in a release so new
that even NixOS unstable doesn't yet have it.  Meanwhile, this Nix stuff is
hard and weird. I might as well be running Arch BTW if it's just a half
solution."

First of all, Nix is hard and weird and it's totally understandable and
righteous that people bounce off it for these reasons.  I am suspicious of
people who tell me arbitrarily hard problems can be solved with a ten-line
change to a config file too.

NixOS is hard, and its quirky language syntax doesn't at all help the case
against it being weird.  But I've found that much of what makes it hard isn't
the language.  Obviously, the problem it's trying to solve is hard.  And in the
"isn't fixed in a version packaged by NixOS" case, it does a pretty good job of
going the extra mile to try to help you solve problems. It's kinda mostly built
on fundamentals that implement this extra mile.

What is ``nixpkgs-unstable.pipewire``?  It's this file:
https://github.com/NixOS/nixpkgs/blob/nixos-unstable/pkgs/development/libraries/pipewire/default.nix
.  That is the set of instructions required to build all of the software
required by the Pipewire service.  You're right, it's weird and hard, my feet
smell and I don't love Jesus, and all those things.

But the bundling of instructions about how to build packages is valuable.  The
ability to theoretically do these things is concretely valuable:

- Add a patch.

- Change the version number and/or git tag used to build the source.

- Change the features that are enabled or disabled when it builds.

- Change the version of a dependency

The meat of ``default.nix`` is a call to ``stdenv.mkDerivation``, the arguments
to which specify where the Pipewire source is, what its dependencies are,
instructions to apply some Nix-specific patches, and a bunch of options for
various features of Pipewire to enable or disable.  Changing it will let us do
all the above-enumerated things.

Let's say you've prepared a patch to a tagged version of Pipewire available
from GitLab.  ``nixpkgs`` Pipewire ``default.nix`` can be changed::

  patches = [
    # Load libjack from a known location
    ./0060-libjack-path.patch
    # Move installed tests into their own output.
    ./0070-installed-tests-path.patch
    # MY CUSTOM PATCH
    ./my-custom.patch
  ];

Then change the ``fetchFromGitLab`` arguments to fetch the right GitLab
revision and change the resulting SHA.

Then if we fork ``nixpkgs`` on GitHub, and apply the changes we made to
Pipewire's ``default.nix`` and add our patch, and check that stuff in on a
branch, we can then use the result like any other flake input.

Instead of::

      nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";

And the eventual::

      services.pipewire.package = pkgs-unstable.pipewire;

Then we check that in to our nixpkgs fork, and point our ``flake.nix`` at the
fork::

  nixpkgs-pipewire-fix.url = "github:NixOS/mcdonc/nixpkgs/pipewire-fix";

  # and...

  services.pipewire.package = pkgs-pipewire-fix.pipewire;
  
And we now presumably have a fixed Pipewire, and a way to repeat the fixed
build, a reasonably good idea about how to manage future changes to the build,
and a mechanism to contribute the fix to the upstream build.  I think that's
compelling and I that's one reason it's worth using despite a distaste for the
language.
