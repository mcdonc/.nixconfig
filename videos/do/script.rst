=============================================
 NixOS 102: Deploying NixOS to Digital Ocean
=============================================

- Companion to video at ...
  
- See the other videos in this series by visiting the playlist at
  https://www.youtube.com/playlist?list=PLa01scHy0YEmg8trm421aYq4OtPD8u1SN

Video Script
============

Although NixOS isn't officially supported, it's pretty easy to deploy it to
Digital Ocean.

We will use the ``nixos-generators`` project to generate a
DigitalOcean-compatible image, and then we'll upload it to DO.

We'll then be able to create a droplet based on that image.

We can then update the droplet's NixOS config either locally or remotely.

The Files
---------

We will use flakes for this.  Sorry if you're not using flakes, but you should
think about converting if you don't.

Here's the ``flake.nix`` we'll use:

.. code-block:: nix

    # flake.nix
    {
      description = "Digital Ocean Demo";

      inputs = {
        nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
        nixos-generators.url = "github:nix-community/nixos-generators";
        nixos-generators.inputs.nixpkgs.follows = "nixpkgs";
      };

      outputs = inputs: {
        nixosConfigurations = {
          dodemo = inputs.nixpkgs.lib.nixosSystem {
            specialArgs = inputs;
            system = "x86_64-linux";
            modules = [ ./dodemo.nix ];
          };
        };
      };
    }

Here is the file named ``dodemo.nix`` referred to by ``flake.nix``:

.. code-block:: nix

    # dodemo.nix
    { lib, pkgs, nixpkgs, nixos-generators, system, ... }:

    {
      imports = [
        "${nixpkgs}/nixos/modules/virtualisation/digital-ocean-config.nix"
        nixos-generators.nixosModules.all-formats
      ];

      networking.hostId = "bd246190";
      networking.hostName = "dodemo";
      system.stateVersion = "25.05";

      environment.systemPackages = with pkgs; [
        vim
        wget
        curl
      ];

      nix = {
        settings = {
          tarball-ttl = 300;
          auto-optimise-store = true;
          experimental-features = "nix-command flakes";
          trusted-users = [ "root" "@wheel" ];
        };
        gc = {
          automatic = true;
          dates = "weekly";
          options = "--delete-older-than 30d";
        };
      };

      nixpkgs.config.allowUnfree = true;

      networking.firewall.enable = true;
      networking.firewall.allowedTCPPorts = [ 22 80 443 ];

      time.timeZone = "America/New_York";

      environment.variables = {
        EDITOR = "vi";
      };

      i18n.defaultLocale = "en_US.UTF-8";

      i18n.extraLocaleSettings = {
        LC_ADDRESS = "en_US.UTF-8";
        LC_IDENTIFICATION = "en_US.UTF-8";
        LC_MEASUREMENT = "en_US.UTF-8";
        LC_MONEY = "en_US.UTF-8";
        LC_NAME = "en_US.UTF-8";
        LC_NUMERIC = "en_US.UTF-8";
        LC_PAPER = "en_US.UTF-8";
        LC_TIME = "en_US.UTF-8";
      };

      services.openssh = {
        enable = true;
        settings = {
          PasswordAuthentication = false;
          PermitRootLogin = "no";
        };
      };

      programs.git.enable = true;

      users.users.chrism = {
        isNormalUser = true;
        initialPassword = "pw321";
        extraGroups = [
          "wheel"
        ];
        openssh = {
          authorizedKeys.keys = [
            "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOLXUsGqUIEMfcXoIiiItmGNqOucJjx5D6ZEE3KgLKYV ednesia"
          ];
        };
      };
    }

These lines in our ``dodemo.nix`` file are what cause the magic to happpen:

.. code-block:: nix

      imports = [
        "${nixpkgs}/nixos/modules/virtualisation/digital-ocean-config.nix"
        nixos-generators.nixosModules.all-formats
      ];

When we include the ``digital-ocean-config.nix``, the built image will use the
right virtual disk setup.  We include the ``all-formats`` line to be able to
invoke a command to build a Digital Ocean image.

The remainder of ``dodemo.nix`` is just normal Nix configuration.  Importantly,
it includes a ``users`` definition for, in this case, ``chrism``.  The user
definition includes a public key for SSH login.  It also enables an SSH daemon.

When we put those files in the same directory, we can then do::
  
  nix build ".#nixosConfigurations.dodemo.config.formats.do"

In the command above, ``dodemo`` is the hostname, and ``do`` (digital ocean) is
the format we're constructing an image for.  ``nixos-generators`` is willing to
generate a DigitalOcean-specific image for us but it can also generate ISOs and
other kinds of images. See the `nixos-generators project
<https://github.com/nix-community/nixos-generators>`_ project for the details.

It will create an image in the ``result`` directory.  We'll upload the image to
a server we own on the Internet in order for Digital Ocean to be able to
download it.::

  scp result/nixos-image-digital-ocean-25.05.20250522.55d1f92-x86_64-linux.qcow2.gz bouncer.repoze.org:static

It's also possible to just upload it from a form on the DO website, but browser
uploads of large files are always fraught.

If we now navigate to the Digital Ocean "Backups and Snapshots" page, then the
"Custom Images" tab, we can click "Import via URL."  Input the URL.

It will take a minute or so for Digital Ocean to validate the image.  It will
be in the "Pending" state until it's validated.

Once it's out of the "Pending" state, we can create a droplet based on the
image.

We can then login to the new droplet using ``chrism``.

At this point, we can set up the droplet's ``/etc/nixos`` from our files if we
want to manage it manually like any other of our systems.

We can alternately use a remote build from our local system::

  nixos-rebuild switch --flake ".#dodemo" --target-host chrism@ipaddr --use-remote-sudo  

Integrating This into an Existing NixOS Flake
---------------------------------------------

It's possible to integrate this into your multisystem flake instead of
maintaining it separately. See `my Nix config
<https://github.com/mcdonc/.nixconfig/blob/master/flake.nix>`_ for more
information (search for "dodemo").
