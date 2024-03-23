==========================================================================
NixOS 80: Flakes + Home Manager Multiuser/Multihost Configuration (Part 2)
==========================================================================

- Companion to video at https://www.youtube.com/watch?v=CA8V2hEIxCc

- This text script available via link in the video description.

- See the other videos in this series by visiting the playlist at
  https://www.youtube.com/playlist?list=PLa01scHy0YEmg8trm421aYq4OtPD8u1SN

Script
======

In `part 1 of this series <https://youtu.be/e8vzW5Y8Gzg>`_ I created a
flake-based NixOS configuration that is can configure three different hosts and
I pushed it up to GitHub at https://github.com/mcdonc/peruserperhost .  As it
stands, all hosts share a common set of globally-available programs and
services; really the only difference right now between the host configurations
of ``host1``, ``host2`` and ``host3`` is their hostname.

By the way, if you want more basic context about NixOS flakes, I'd suggest you
watch `a video I made about flakes out of the box
<https://www.youtube.com/watch?v=hoB0pHZ0fpI>`_ or read its `talky-script
<https://github.com/mcdonc/.nixconfig/blob/master/videos/flakesootb/script.rst>`_ .  Links will be available in the description.

However, in this continuing part of the series, we have important business to
attend to. It presumes you've watched part 1, for better or worse.  Here's our
intent:

- We'll cause ``host1`` to have a Postgres service running on it that will
  not run on ``host2`` or ``host3``.

- all hosts will get the user environment and the home-manager configuration
  (shell setup, git configuration) of a user named ``alice``.

- ``host3`` will additionally have the user environment and the home-manager
  configuration of a user named ``bob``.

- ``alice`` and ``bob`` will share a common base home-manager configuration, so
  that changing that common base will impact both of them.

- ``host2`` will have special home-manager configuration for the ``alice``
  user; in particular, it will run a *user-level* systemd service as ``alice``.

- ``host3`` will have special home-manager configuration for the ``bob`` user;
  it will add additional shell aliases for bob that aren't shared by ``alice``.

  
Setting Up Postgres on Host 1 (But not on Host 2 or Host 3)
-----------------------------------------------------------

This is falling off a log easy.  While logged into ``host1``, in
``/etc/nixos/host1.nix`` we're going to add the following:

.. code-block:: nix

   services.postgresql.enable = true;

Then we must ``nixos-rebuild switch``.

``host1`` is now running Postgres, we can verify it with a ``systemctl status
postgresql``, but even if we run ``nixos-rebuild switch`` on ``host2`` or
``host3``, they will not be running Postgres, nor will they have any
Postgres-related software installed.

Let's make sure by logging in to ``host2`` and rebuilding.

Dealing with Our Existing ``chrism`` User
-----------------------------------------

For purposes of being able to ssh conveniently to GitHub and other hosts during
this video, I created a user in part 1 named ``chrism``, which I'll retain.
Currently, he is defined within the ``configuration.nix`` file, but we want him
to be defined so that we can include or discinclude his account on any of our
three hosts at our whim.

To get there, while logged into ``host1``, I'll add a ``chrism.nix`` file to
our configuration and I'll move the ``chrism`` user out of
``configuration.nix`` and into ``chrism.nix``, such that it becomes:

.. code-block:: nix

   # chrism.nix

   { pkgs, ...}:

   {
     users.users.chrism = {
       isNormalUser = true;
       description = "Chris McDonough";
       extraGroups = [ "networkmanager" "wheel" ];
       openssh.authorizedKeys.keys = [
         "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOLXUsGqUIEMfcXoIiiItmGNqOucJjx5D6ZEE3KgLKYV ednesia"
        ];
       };
   }
  
Since I still want the ``chrism`` account on all the hosts, I'll change the
``imports`` list of each of ``host1.nix``, ``host2.nix``, and ``host3.nix`` to
import ``chrism.nix``:

.. code-block:: nix

   imports = [
     ./chrism.nix
     ./configuration.nix
   ];

I then need to git add ``chrism.nix`` and try to rebuild.

Commit and push when it works.

Nothing really will have changed, because I'm just moving code around.

Adding the ``alice`` and ``bob`` Unix Users
-------------------------------------------

While still logged in to ``host1``, we'll copy ``chrism.nix`` into both
``alice.nix`` and ``bob.nix`` and change the username and description in each
as necessary.  We don't need an ssh configuration yet for either user, so we'll
remove chrism's authorized key from both users' configuration.  Also, neither
``alice`` nor ``bob`` need to be a member of the ``wheel`` group, so we'll take
that out.  We'll also set both of them up with an initial password.

Here's ``alice.nix``

.. code-block:: nix

   # alice.nix

   { pkgs, ...}:

   {
     users.users.alice = {
       isNormalUser = true;
       initialPassword = "abc123";
       description = "Alice";
       extraGroups = [ "networkmanager" ];
       };
   }

Here's ``bob.nix``:

.. code-block:: nix

   # bob.nix

   { pkgs, ...}:

   {
     users.users.bob = {
       isNormalUser = true;
       initialPassword = "abc123";
       description = "Bob";
       extraGroups = [ "networkmanager" ];
       };
   }
   
Then we'll change ``host1.nix``, ``host2.nix`` and ``host3.nix`` so ``alice``
is present on all of them by adding ``alice.nix`` to the imports list of each:

.. code-block:: nix

   imports = [
     ./chrism.nix
     ./alice.nix
     ./configuration.nix
   ];

I then need to git add ``alice.nix`` and try to rebuild.

When the rebuild completes, we'll see that a ``/home/alice`` directory has been
created.

Commit and push when it works.

``git pull`` and rebuild on ``host2`` and ``host3`` to get ``alice`` on both of
those systems.
                
We don't want ``bob`` on ``host1`` or ``host2`` but we do want him on ``host3``
so we'll change ``host3.nix`` such that ``bob.nix`` is in its ``imports`` list.

.. code-block:: nix

   # host3.nix

   imports = [
     ./chrism.nix
     ./alice.nix
     ./bob.nix
     ./configuration.nix
   ];

We'll rebuild on ``host3`` and see that ``bob`` is now present on the system.
Commit and push.

We now have our Unix user acccounts set up properly for ``bob`` and ``alice``
on all systems.  ``alice`` can log in to any of ``host1``, ``host2`` or
``host3`` via ssh.  ``bob`` can log in to ``host3`` but not ``host1`` nor
``host2``.

Getting ``home-manager`` Set Up for Use
---------------------------------------

``home-manager`` allows us to manage user-related dotfiles and other per-user
configuration, like systemd user services.  To use home-manager, we need to
change our ``flake.nix`` file.

We have to add an input for the home-manager URL.  We want it to match the
NixOS release we're using.

.. code-block:: nix

    home-manager.url = "github:nix-community/home-manager/release-23.11";

We need to add ``home-manager`` as an input argument to the ``outputs``, and
capture the ``inputs`` list so we can use it later.

.. code-block:: nix

    outputs = {
      # .. other ...
      home-manager
    }@inputs:

We then need to establish a ``let-in`` block that sets up some variables we
want to use later:

.. code-block:: nix

    let
      system = "x86_64-linux";
      specialArgs = inputs // { inherit system; };
      shared-modules = [
        home-manager.nixosModules.home-manager
        {
          home-manager = {
            useUserPackages = true;
            extraSpecialArgs = specialArgs;
          };
        }
      ];
    in

And finally, we need to change each of our nixosSystems to use the shared
modules, specialArgs, and system we defined in the ``let`` block.

.. code-block:: nix

   nixosConfigurations = {
     host1 = nixpkgs.lib.nixosSystem {
       specialArgs = specialArgs;
       system = system;
       modules = shared-modules ++ [ ./host1.nix ];
     };
     # ... host2 and host3 the same
   };

Our final ``flake.nix`` should look like this:

.. code-block:: nix

   # flake.nix

   {
       description = "My flakes configuration";

       inputs = {
         nixpkgs.url = "github:NixOS/nixpkgs/nixos-23.11";
         home-manager.url = "github:nix-community/home-manager/release-23.11";
       };

       outputs = { self, nixpkgs, home-manager }@inputs:
         let
           system = "x86_64-linux";
           specialArgs = inputs // { inherit system; };
           shared-modules = [
             home-manager.nixosModules.home-manager
             {
               home-manager = {
                 useUserPackages = true;
                 extraSpecialArgs = specialArgs;
               };
             }
           ];
         in
         {
           nixosConfigurations = {
             host1 = nixpkgs.lib.nixosSystem {
               specialArgs = specialArgs;
               system = system;
               modules = shared-modules ++ [ ./host1.nix ];
             };
             host2 = nixpkgs.lib.nixosSystem {
               specialArgs = specialArgs;
               system = system;
               modules = shared-modules ++ [ ./host2.nix ];
             };
             host3 = nixpkgs.lib.nixosSystem {
               specialArgs = specialArgs;
               system = system;
               modules = shared-modules ++ [ ./host3.nix ];
             };
           };
         };
   }


Note that we could have spelled:

.. code-block:: nix
                
       specialArgs = specialArgs;
       system = system;

instead as:

.. code-block:: nix
                
       inherit specialArgs system;

But the former is clearer, even though it's more to type.

Now we'll try to rebuild on ``host1``.  If it works, we'll see an input added
for home-manager in the output of ``nixos-rebuild``.  Commit and push once it
works.

Giving ``alice`` and ``bob`` Home-Manager Configurations
--------------------------------------------------------

On ``host1``, we're going to add the following into ``alice.nix`` in order to
configure Alice's Git username and email settings declaratively whenever we
rebuild.  We'll also set the baseline state version of home-manager for
beancounting purposes.

.. code-block:: nix

   # alice.nix

   home-manager = {
     users.alice = {
       programs.git = {
         enable = true;
         userName = "Alice";
         userEmail = "alice@example.com";
       };
       home.stateVersion = "23.11";
     };
   };

We'll do something similar for Bob in ``bob.nix``.

.. code-block:: nix

   # bob.nix

   home-manager = {
     users.bob = {
       programs.git = {
         enable = true;
         userName = "Bob";
         userEmail = "bob@example.com";
       };
       home.stateVersion = "23.11";
     };
   };

Rebuild to see that ``/home/alice/.config/git/config`` is a symlink into the
Nix store and has the proper contents referring to Alice.  If we commit, push,
and rebuild ``host3``, we will see something similar for Bob.

We also want Bob and Alice to share some home-manager configuration, so on
``host1``, let's make a file named ``home.nix`` that contains configuration
that will provide a ``ll`` shell alias when either is in a ``bash`` interactive
shell.

.. code-block:: nix

  # home.nix

  { pkgs, ...}:

  {
    programs.bash = {
      enable = true;
      shellAliases = {
        ll = "${pkgs.coreutils}/bin/ls -al";
      };
    };
   }

Run ``git add home.nix``.

Then we will add the following into ``users.alice`` within ``alice.nix`` and
into ``users.bob`` within ``bob.nix`` to include the shared home-manager
configuration from ``home.nix``.

.. code-block:: nix

   imports = [ ./home.nix ];

Thus, ``alice.nix`` becomes:

.. code-block:: nix

   # alice.nix

   home-manager = {
     users.alice = {
       imports = [ ./home.nix ];
       programs.git = {
         enable = true;
         userName = "Alice";
         userEmail = "alice@example.com";
       };
       home.stateVersion = "23.11";
     };
   };

And ``bob.nix`` becomes:

.. code-block:: nix

   # bob.nix

   home-manager = {
     users.bob = {
       imports = [ ./home.nix ];
       programs.git = {
         enable = true;
         userName = "Bob";
         userEmail = "bob@example.com";
       };
       home.stateVersion = "23.11";
     };
   };
   
Try to rebuild.  Once the rebuild works, ``su - alice`` and see that running
``ll`` as ``alice`` produces the right output and ``type ll`` tells us it's a
shell alias.  On ``host3``, this will also be the case for ``bob``.

Commit and push when it all works.
