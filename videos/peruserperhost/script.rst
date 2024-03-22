===========================================================================
 NixOS 79: Use Flakes + Home-Manager to get Per-User-Per-Host Configuration
===========================================================================

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
          
In this video, I'll dive in a little deeper and set up three NixOS machines,
``host1``, ``host2``, and ``host3``.  They will be configured like this:

- all hosts will share a common set of globally-available programs and
  services.

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
  will add additional shell aliases for fred that aren't shared by ``alice``.

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

- Copy our ssh configuration over to the new machine from another host:

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

The Second Host
---------------

Let's revisit ``/etc/nixos/flake.nix``:

.. code:: nix

    {
      description = "My flakes configuration";

      inputs = {
        nixpkgs.url = "github:NixOS/nixpkgs/nixos-23.11";
      };

      outputs = { self, nixpkgs }@inputs:
        {
          nixosConfigurations = {
            nixos = nixpkgs.lib.nixosSystem {
              system = "x86_64-linux";
              modules = [ ./configuration.nix];
            };
          };
        };
    }

See "nixos = nixpkgs.lib.nixosSystem" there?  that says "use this configuration
for a system with the *hostname* ``nixos``, which by default is the hostname
given to a new system created by the installer, and which is changeable in
``/etc/nixos/configuration.nix``.  If you want to add another machine to your
configuration in the future, you can just give it a different hostname, and
refer to slightly different configurations for different systems in
``flake.nix``, e.g.:

.. code:: nix

      outputs = { self, nixpkgs }@inputs:
        {
          nixosConfigurations = {
            nixos = nixpkgs.lib.nixosSystem {
              system = "x86_64-linux";
              modules = [ ./configuration.nix];
            };
            myothersystem = nixpkgs.lib.nixosSystem {
              system = "x86_64-linux";
              modules = [ ./configuration.nix ./moreconfig.nix];
            };
          };
        };
          
Then run nixos-rebuild on the host you named ``myothersystem`` and it will have
all the configuration implied by both ``configuration.nix`` and
``moreconfig.nix``.  Rinse and repeat for every system in your life.  Allowing
systems to share the same configuration this way is one of the benefits of
flakes-based configuration.

  
Blather
=======

I'm not going to go into making other changes to ``flake.nix``.  Plenty of
YouTube videos, blog entries, and other resources are available for that.  But
we can see that flakes-based configuration is really just a layer on top of the
legacy configuration service; one which can use files
(e.g. ``configuration.nix`` and ``hardware-configuration.nix``) that were
generated under the old configuration regime.

I've been talking as if ``flake.nix`` is a feature only useful to configure
NixOS.  It is actually a much more general system, and can be used to build
projects other than NixOS.  Nix developers are, as we speak, busy creating
registries of flakes that build software and services by just feeding a URL to
the ``nix run`` command.

For example, you can install a MacOS X Ventura virtual machine by doing::

  nix run github:matthewcroughan/NixThePlanet#macos-ventura

Under the hood, that uses a flake.

Demo
----

- Terminal font size

- bridged networking

- bidirectional shared clipboard

- $ cd /etc/nixos
  $ sudo chown -R chrism:users .

- in configuration.nix:

  - hostname

  - enable ssh

  - nixos-vm config

  - git, emacs, vim

  nix = {
    settings = {
      experimental-features = "nix-command flakes";
    };
  };

  # replaces
  nix = {
    package = pkgs.nixUnstable;
    extraOptions = ''
      experimental-features = nix-command flakes
    '';
  };

- Reboot
  
- scp -r ~/.ssh 192.168.1.153:

  git config --global user.email "chrism@plope.com"
  git config --global user.name "Chris McDonough"
  git commit -a -m "first commit"
  git push -u origin master

- add flake.nix

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

Modify configuration.nix

  - hostname

Rebuild

Add, Commit and push

