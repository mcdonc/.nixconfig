=====================================================================================
 NixOS 79: Use Flakes + Home-Manager to get Per-User-Per-Host Configuration (Part 1)
=====================================================================================

- Companion to video at 

- This text script available via link in the video description.

- See the other videos in this series by visiting the playlist at
  https://www.youtube.com/playlist?list=PLa01scHy0YEmg8trm421aYq4OtPD8u1SN

Script
======

I made a `video not long ago
<https://github.com/mcdonc/.nixconfig/blob/master/videos/flakesootb/script.rst>`_
that detailed how to get NixOS 23.11 configured in "flakes mode" right after it
has first been installed.  The purpose of the video was to demonstrate that a
NixOS flake is just a layer on top of Nix legacy ``configuration.nix``
configuration.  In that video, I made a claim: using a flake to configure your
NixOS systems really is better than using legacy mode.  But I didn't much
substantiate that claim except by hand-waving about how you could add another
host as a named ``nixosConfigurations.nixosSystem`` to the ``outputs`` of your
``flake.nix``, something like this:

.. code-block:: nix

      outputs = { self, nixpkgs }@inputs:
        {
          nixosConfigurations = {
            host1 = nixpkgs.lib.nixosSystem {
              system = "x86_64-linux";
              modules = [ ./configuration-host1.nix ];
            };
            host2 = nixpkgs.lib.nixosSystem {
              system = "x86_64-linux";
              modules = [ ./configuration-host2.nix ];
            };
          };
        };
          
In part1 of this series, I'll dive in a little deeper and set up three NixOS
machines, ``host1``, ``host2``, and ``host3``.  They will be configured like
this:

- all hosts will share a common set of globally-available programs and
  services.

In part 2 of this series:

- all hosts will have the user environment and the home-manager configuration
  (shell setup, ssh configuration, etc) of a user named ``alice``.

- host3 will additionally have the user environment and the home-manager
  configuration of a user named ``bob``.

- ``alice`` and ``bob`` will share a common base set of home-manager
  configuration stuff.

- host1 will have a *system-level* systemd service running on it that is not
  running on host2 or host3.

- host2 will have special home-manager configuration for the ``alice`` user; in
  particular, it will run a *user-level* systemd service as ``alice``.

- host3 will have special home-manager configuration for the ``bob`` user; it
  will add additional shell aliases for bob that aren't shared by ``alice``.

That means that we will be able to deploy a host:

- with some number of user environments.

- those user environments can share a base pool of settings.

- but we can specialize the user environments as necessary.

And we can deploy multiple hosts:

- each with a common set of programs and system-level configuration.

- but specializable settings and system-level configuration can be tied to a
  particular host.

This will let us share the vast majority of host configuration between hosts
and the vast majority of user configuration between users. But in a pinch, it
will let us get very granular, letting us set up some service or program on one
host that isn't on another, and letting us give some user some service or
setting on one particular host, without needing to give that user the same
setting on another host.

Of course this is totally doable on other Linux systems using something like
Ansible and some imperative per-host, per-user setup code, but we will do it
all declaratively, within Nix files.

Setting Up the First Host
-------------------------

We'll start out right after a reboot of the NixOS installer of the system that
we want to call ``host1``. We need to modify the default configuration to put
it into flakes mode, make some changes to the ``configuration.nix`` file, check
in our ``/etc/nixos`` files into a Git repository, and push it all up to
GitHub.

If you want more context about flakes, watch `the flakes out of the box video
<https://www.youtube.com/watch?v=hoB0pHZ0fpI>`_ or read its `talky-script
<https://github.com/mcdonc/.nixconfig/blob/master/videos/flakesootb/script.rst>`_:

First we change some permissions so we don't have to sudo all the time::

  $ cd /etc/nixos
  $ sudo chown -R chrism:users .

In ``/etc/nixos/configuration.nix`` we're going to:

- Change the hostname from ``nixos`` to ``host1``

- Enable an ssh server

- Enable git and our favorite editor so we don't lose our minds using nano.

- Add some nix configuration that allows us to use flakes:

  .. code-block:: nix

    nix = {
      settings = {
        experimental-features = "nix-command flakes";
      };
    };

- And for me only, since I'm using virtual machines for this video, I need to
  add some VM hair that lets me cut and paste across the host and the ``host1``
  VM:

  .. code-block:: nix

                  
     virtualisation.virtualbox.guest = {
       enable = true;
       x11 = true;
     };

- Note our host's IP address via ifconfig

Then we need to run ``nixos-rebuild switch`` and reboot.

Once rebooted:

- Copy our ssh configuration over to the new machine from another host::

    scp -r ~/.ssh <hostip>:

- Edit our ``/etc/nixos/configuration.nix`` so our ssh public key is associated
  with our user:

  .. code-block:: nix

    users.users.chrism = {
      # .. other config ..
      openssh = {
          authorizedKeys.keys = [
            "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOLXUsGqUIEMfcXoIiiItmGNqOucJjx5D6ZEE3KgLKYV ednesia"
          ];
        };
     };

- Get git configured for first-time use::

   git config --global user.email "chrism@plope.com"
   git config --global user.name "Chris McDonough"

- add an ``/etc/nixos/flake.nix`` file:

  .. code-block:: nix

    {
    description = "My flakes configuration";

    inputs = {
      nixpkgs.url = "github:NixOS/nixpkgs/nixos-23.11";
    };

    outputs = { self, nixpkgs }@inputs:
      {
        nixosConfigurations = {
          host1 = nixpkgs.lib.nixosSystem {
            system = "x86_64-linux";
            modules = [ ./configuration.nix];
          };
        };
      };
    }

- Run ``git init`` within our ``/etc/nixos`` directory.

- Commit all of the files in the /etc/nixos directory to our local git
  repository::

   git add flake.nix configuration.nix hardware-configuration.nix

- Rerun ``nixos-rebuild switch`` to test our config out.

- Git add the generated ``flake.lock`` file when it all works::

   git add flake.lock
   
- Commit::
    
   git commit -a -m "first commit"

- Create a GitHub repository named ``peruserperhost`` that we can push our
  changes to.  

- Push our local git commits to GitHub.  We'll use this repository to manage
  all of our host configurations::

    git remote add origin git@github.com:mcdonc/peruserperhost.git
    git push -u origin master

Factoring our Configuration to Let Us Add a Second Host
-------------------------------------------------------

In my `flakes OOTB video talky-script
<https://github.com/mcdonc/.nixconfig/blob/master/videos/flakesootb/script.rst>`_,
I handwaved about changing ``flake.nix`` so that we can use the same Git
repository to manage not just one host, but two or more hosts.  Let's change
things around so that we can actually do that now.

We want to leave most of the networking, services, desktop environment, user,
and program configuration in ``configuration.nix`` alone so that we can share
it with other hosts, but we don't want the ``hardware-configuration.nix`` to be
shared between multiple hosts.  Each host will have its own hardware
configuration in a nix file named after the host instead, and we'll move some
configuration that isn't appropriate to share between hosts from
``configuration.nix`` into that file too.

We haven't got to factoring out our user configuration or adding in
home-manager yet, we will do that in a little while.

To do this, we will:

- Rename ``hardware-configuration.nix`` to ``host1.nix``.

- Remove the import of ``hardware-configuration.nix`` from
  ``configuration.nix``.

- Add an import of ``configuration.nix`` to ``host1.nix``.

- Move the ``boot.loader.*`` directives from ``configuration.nix`` to
  ``host1.nix``.

- Move the ``networking.hostName`` from ``configuration.nix`` to ``host1.nix``.

- Change modules of host1 nixConfiguration in ``flake.nix`` from
  ``[ ./configuration.nix ]`` to ``[ ./host1.nix ]``.

- Try to rebuild via ``nixos-rebuild switch``.  Nothing should have changed.

Adding a Second Host
--------------------

We're now going to add a second host to our configuration.  I'll create a
second VM by using the NixOS installer again, then I'll make some changes to
the result.

I will repeat some of the steps I took in the last stage.  I will:

- Enable ssh server, add git emacs and vim, change hostname to "host2" like
  last time.

- Rebuild.

- Reboot.

- Copy my ssh keys over like last time.

- Get git configured for first-time use like last time::

   git config --global user.email "chrism@plope.com"
   git config --global user.name "Chris McDonough"

- I will not make further changes to anything in ``/etc/nixos``.  Instead
  I'll move it aside, check out my GitHub repository and turn it into a new
  ``/etc/nixos``::

    cd ~
    git clone git@github.com:mcdonc/peruserperhost.git
    sudo mv /etc/nixos /etc/nixos_aside
    sudo mv peruserperhost /etc/nixos

- Copy the ``hardware-configuration.nix`` from ``/etc/nixos_aside`` into
  ``/etc/nixos/host2.nix``.

- Add ``./configuration.nix`` to the imports list of ``host2.nix``.

- Copy the ``boot.loader.*`` directives and the hostname over from
  ``/etc/nixos_aside/configuration.nix`` to ``host2.nix``.

- Add a ``host2`` nixosSystem to ``nixosConfigurations`` in ``flake.nix``.

  .. code-block:: nix

          host2 = nixpkgs.lib.nixosSystem {
            system = "x86_64-linux";
            modules = [ ./host2.nix ];  
          };

- Add ``host2.nix`` to the git staging area::

    git add host2.nix

- Rebuild.

- Commit the changes to git and push::

    git commit -a -m "add host2"
    git push

We now have a second system which shares most of its configuration with the
first system.  In fact, the only real difference between them is a hostname.
But we now have a place to hang host-specific configuration.  If we want
something special on host1, we can add stuff to ``host1.nix``, likewise if we
want something special on host2, we can add it too ``host2.nix``.  Changes we
make to a host-specific file won't be reflected in the configuration of any
other host.

Adding a Third Host
-------------------

I'll repeat the dance I did for ``host2`` to make a ``host3``, at which point
we will start to be able to make the host-specific and user-specific
specializations I promised in the introduction to this video.

Denouement
----------

In part 2, I will get ``alice`` and ``bob`` set up as well as specialize
services per-host.
