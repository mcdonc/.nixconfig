==========================================================
 NixOS 65: Using devenv on Ubuntu and devenv's Pain Points
==========================================================

- Companion to video at 

- This text script available via link in the video description.

- See the other videos in this series by visiting the playlist at
  https://www.youtube.com/playlist?list=PLa01scHy0YEmg8trm421aYq4OtPD8u1SN

Overview
========

I recently made a `video <https://www.youtube.com/watch?v=wPp2DJJpCAg>`_ in my
`NixOS on a Thinkpad
<https://www.youtube.com/playlist?list=PLa01scHy0YEmg8trm421aYq4OtPD8u1SN>`_
series describing my use of `devenv <https://devenv.sh>`_ on NixOS.

Devenv is a project by Domen Kozar that makes it possible to repetatably build
and rebuild development environments.  It is a wrapper around `Nix
<https://nixos.org/download#download-nix>`_ which a package manager as well as
a repository of around 80,000 packages.  Because it uses Nix, and because Nix
itself is cross-platform, devenv is actually useful on basically any Linux
platform (including under Windows' WSL) as well as MacOS.  It's pretty cool.

While making my prior video was entertaining, it fell short of showing how
devenv is actually useful, because I demonstrated it on NixOS rather than on a
platform that normal people use, and I demonstrated it in a mode ("flakes"
mode) that most people would not choose to use.

In this video, I'd like to show you how to install devenv on Ubuntu, and spin
up a Python development environment like a human (not a NixOS user) might.  I
will also discuss some of the shortcomings of devenv and Nix; it's not all
roses.

Installation
============

On Ubuntu, as a normal user::

      $ curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install

Then edit ``/etc/nix/nix.conf``, adding this (where chrism is your username)::

      trusted-users = chrism

Reboot (I'm sure there's a better way, but this works).

Upon reboot, run these commands in sequence::

      $ nix profile install nixpkgs#cachix
      $ cachix use devenv
      $ nix profile install --accept-flake-config tarball+https://install.devenv.sh/latest

Devenv is now installed.

Using Devenv
============

In the last video, I created a Python development environment.  I will use the
same application and configuration for this video.

I ran "devenv init" inside of that package and the result is the set of files
in https://github.com/mcdonc/.nixconfig/tree/master/videos/devenv-ubuntu/myproj .

I changed ``devenv.nix`` and ``devenv.yaml`` inside there to get it working.

I'll check the repository that contains the project out::

  $ mkdir ~/projects
  $ cd ~/projects
  $ git clone git@github.com:mcdonc/.nixconfig.git

Then I'll use devenv to get it running::

  $ cd ~/projects/.nixconfig/videos/devenv-ubuntu/myproj
  $ devenv shell
    ... ....
  $ devenv up


Pain Points
===========

Devenv currently has a number of sharp edges (Dec. 2023).  These are not
complaints, just realities, only fixed when people like you and me contribute.

Long-Lived ``python-rewrite`` Branch
------------------------------------

Devenv is undergoing some heavy changes.  In particular, it has a long-lived
branch named "python-rewrite" which fixes a bunch of existing issues.  The
branch rewrites most of the shell code that is on master in Python.  It fixes
so many issues that it has turned out, for me, at least, to be a must-use.  But
is unfinished, and probably introduces some new bugs, and seems to be changing
quicky.  There is no ETA for its completion.

As an example of the pain this causes, ``languages.python.venv`` doesn't seem
to work on the ``python-rewrite`` branch at the moment (it did yesterday).

``languages.python.version`` Doesn't Really Work
------------------------------------------------

If you try to use it, all kinds of weirdness happens on the master branch.  If
you use it on the ``python-rewrite`` branch, it's less weird but still weird.
Too complicated to explain here, but failures to load shared libraries is the
main symptom.

Non-Parity Between "normal" and "flakes" Modes
----------------------------------------------

Devenv can operate in two modes: "normal" mode, in which ``devenv shell`` is
used and "flakes" mode, in which ``devenv shell`` is replaced by
``nix develop --impure``. 

In normal mode, the contents of a YAML file named ``devenv.yaml`` are used to
dynamically construct a flake file that Nix uses under the hood.  However,
flakes mode requires no YAML.  It's all just Nix, including a static
``flake.nix`` file.  In flakes mode, you just edit the static ``flake.nix``;
you don't edit any YAML and ``devenv.yaml`` doesn't exist.

I prefer the flakes mode and I'm glad it exists.  Here's why: I would rather
not be protected from the complexity of a static flake file that I can just
edit directly, because trying to divine how the JSON maps to the creation of
the dynamic flake is not trivial.  It's actually harder, I've found, than just
maintaining a static flake file.  This is ironic, because it's supposed to
shield users from complexity.  But I've found it a bit painful to do things
that are required in the real world within the ``devenv.yaml`` file.  Overlays,
in particular.  Additionally, the JSON will, by its nature, never expose all
the features of a static flake, and I'm concerned that if I use normal mode
(and thus YAML), I will have to extend devenv itself to get a feature that only
I need.  This isn't something I'd like to sign up for at the moment, so I will
use flakes mode for the foreseeable future.

However, currently, the containerization feature (``devenv container up``,
``devenv container shell``, etc) is unimplemented in flakes mode.  So, at the
moment, I'll need to extend devenv if I want to use containerization and flakes
mode together.

Build Times
-----------

There is also an issue with build times.  This isn't really a devenv
problem, it's a Nix one.  Nix allows for "overlays" where you can change the
version of a package used by the build environment, or a config file it uses,
or any number of its properties.  However, when you use an overlay against a
package, every dependent package usually must be recompiled.

If you need to change how -- say -- openssl is compiled, even slightly, you can
be sure that you're going to wait a long time for the resulting environment to
be regenerated when you do ``devenv shell`` or ``nix develop``, because it will
also need to compile all the packages you're using that are dependent upon
``openssl``.  This can be mitigated with the use of a binary cache service like
Cachix, but in my case, the change I want (to openssl) doesn't warrant waiting
for several hours for the thing to recompile all the dependents and populate a
custom cache with several gigabytes of new derivations, then maintain that
cache forever.  The change is trivial and doesn't change the API of openssl at
all (I am just changing the openssl config file).  Instead, I should just be
able to do something like Guix does with its "grafts" and tell the dependent
packages don't worry about this particular change, don't recompile, just
rewrite your existing dependents to depend on my new openssl.

There is a feature in NixOS called ``system.replaceRuntimeDependencies`` that
would allow me to do just that, but maddeningly this is just a feature of
NixOS, not of plain-old-Nix, so I can't use it in devenv.  This may be a bit of
a showstopper for me because I don't think I have the Nix-fu to implement a
plain-Nix ``replaceRuntimeDependencies``.

