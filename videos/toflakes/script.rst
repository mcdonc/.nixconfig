NixOS 40: Converting an Existing NixOS Configuration To Flakes
==============================================================

- Companion to video at

- See the master branch of https://github.com/mcdonc/.nixconfig for a working
  Flakes-based configuration.

- See the other videos in this series by visiting the playlist at
  https://www.youtube.com/playlist?list=PLa01scHy0YEmg8trm421aYq4OtPD8u1SN

Video Script
------------

- NixOS 23.05 is coming out pretty soon.  Good excuse to stop ignoring flakes.

- Currently I have an ``/etc/nixos/configuration.nix`` for one of my computers
  that looks something like this::

     { config, pkgs, lib, ... }:

     let
       hw = fetchTarball
         "https://github.com/NixOS/nixos-hardware/archive/master.tar.gz";
     in {
       imports = [
         (import "${hw}/lenovo/thinkpad/p52")
         ../common/pseries.nix
         ../common/encryptedzfs.nix
         ../common/configuration.nix
         ../common/rc505.nix
         ../common/home/chrism.nix
       ];

       boot.consoleLogLevel = 3;

       # per-host settings
       networking.hostId = "e1e4a33b";
       networking.hostName = "thinknix52";

     }

- The contents of ``/etc/nixos`` are actually a checkout of a git repository.
  The git repository has a structure something like this::

     .
     ├── common
     │   ├── configuration.nix
     │   ├── encryptedzfs.nix
     │   ├── home
     │   │   ├── chrism.nix
     │   │   ├── emacs
     │   │   ├── larry.nix
     │   │   ├── p10k
     │   │   └── steam.desktop
     │   ├── pseries.nix
     │   ├── rc505.nix
     │   ├── roland.patch
     │   ├── sessile.nix
     │   └── tseries.nix
     ├── hosts
         ├── thinknix420.nix
         ├── thinknix50.nix
         ├── thinknix512.nix
         ├── thinknix51.nix
         ├── thinknix52.nix
         └── vanilla.nix

- On each system I own, I created a symlink ``/etc/nixos/configuration.nix``
  that points at a nix file representing the appropriate system in
  ``/etc/nixos/hosts`` (in this case, ``/etc/nixos/configuration.nix`` is a
  symlink to ``/etc/nixos/hosts/thinknix52.nix``).

- There are lots of details about what all the ``.nix`` files imported within
  ``/etc/nixos/hosts/thinknix52.nix`` do, but let's ignore those for now.  What
  I'd like to do is the minimum amount of work to change my Git repository
  around such that:

  - I no longer need a ``/etc/nixos/configuration.nix`` symlink on any system.
    In its place I can have a ``/etc/nixos/flake.nix`` in my repository that
    describes *all* of my systems.  To add a new system, instead of creating
    the ``/etc/nixos/configuration.nix`` symlink to a nix file that describes a
    particular system in my Git repo, I should be able to edit
    ``/etc/nixos/flake.nix`` to add the new system.

  - I don't rebuild my home-manager configuration separately from
    ``nixos-rebuild``.  Instead, if I need to make a change to my user's
    home-manager configuration, I change files under ``/etc/nixos`` and run
    ``nixos-rebuild``.  I want this to continue to work.

  - After adding the ``/etc/nixos/flake.nix``, I'd like to be able to run
    ``nixos-rebuild switch --flake`` and get approximately the same result that
    I got when I ran ``nixos-rebuild switch`` when ``/etc/nixos/flake.nix`` did
    not exist.

- To get started, I created a new branch in my configuration repository
  (e.g. ``git checkout -b flakes``) so I could go back to a known working
  config at any time.

- Once I switched to the new branch, I added experimental flakes support to my
  configuration by adding this within my
  ``/etc/nixos/common/configuration.nix``::

    nix.package = pkgs.nixUnstable;
    nix.extraOptions = ''
      experimental-features = nix-command flakes
      '';

  Then I rebuilt.

- And then, I created a ``/etc/nixos/flake.nix`` file that looked something
  like this::

     {
       description = "Chris' Jawns";

       inputs = {
         nixpkgs.url        = "github:NixOS/nixpkgs/nixos-22.11";
         nixos-hardware.url = "github:NixOS/nixos-hardware";
         home-manager.url = "github:nix-community/home-manager/release-22.11";
       };

       outputs = { self, nixpkgs, nix, nixos-hardware, home-manager }: {
         nixosConfigurations = {
           thinknix52 = nixpkgs.lib.nixosSystem {
             system = "x86_64-linux";
             modules = [
               nixos-hardware.nixosModules.lenovo-thinkpad-p52
               ./hosts/thinknix52.nix
               ./users/chrism/user.nix
               home-manager.nixosModules.home-manager {
                 home-manager.useUserPackages = true;
                 home-manager.users.chrism = import ./users/chrism/hm.nix;
               }
             ];
           };
         };
       };
     }

- Note that if ``/etc/nixos/flake.nix`` exists, you needn't specify
  ``nixos-rebuild --flake`` as per the documentation.  It will assume you want
  to use ``flake.nix`` and flakes.  Its mere presence means "I want to use
  flakes", which can be confusing if you leave it there and want to go back to
  the old regime.

  Note also that a flake-based configuration must be in a Git repository (I
  think, at least I didn't try it outside one).  And it badly wants you to at
  least *add* new files you create in the repository to the repository.  It
  refeuses to recognize them if you don't (failing with a "file not found"
  error, confusingly).

- Let's take a look at the ``inputs`` attrset::

       inputs = {
         nixpkgs.url        = "github:NixOS/nixpkgs/nixos-22.11";
         nixos-hardware.url = "github:NixOS/nixos-hardware";
         home-manager.url = "github:nix-community/home-manager/release-22.11";
       };

  Coming to this this took some time.  Currently, there is a problem with
  mixing and matching ``nixpkg`` and ``home-manager`` repositories that do not
  share the same version.  Most (all) of the explanations of how to create a
  working ``/etc/nixos/flake.nix`` tend to show something like this::

       inputs = {
         nixpkgs.url        = "github:NixOS/nixpkgs/nixos-22.11";
         nixos-hardware.url = "github:NixOS/nixos-hardware";
         home-manager = {
             url = "github:nix-community/home-manager";
             inputs.nixpkgs.follows = "nixpkgs";
         };
       };

  As of this writing, this fails when you run ``nixos-rebuild`` with something
  like::

    error: attribute 'extend' missing

       at /nix/store/b7dsb1k7j2prpmn9kz1j48aqn00pnmd7-source/modules/lib/stdlib-extended.nix:7:4:

            6| let mkHmLib = import ./.;
            7| in nixpkgsLib.extend (self: super: {
             |    ^
            8|   hm = mkHmLib { lib = self; };
       Did you mean extends?
    (use '--show-trace' to show detailed location information)

  Matching up the versions in the url attributes for ``nixpkgs.url`` and
  ``home-manager.url`` fixed things.  I can't tell you why, and it even seems a
  bit of a mystery to folks who are familiar with both nixpkgs and home-manager
  internals:
  https://discourse.nixos.org/t/completly-lost-with-errors-rror-attribute-extend-missing-at-nix-store-b7/28160

- Let's take a look at the outputs attrset now::

       outputs = { self, nixpkgs, nix, nixos-hardware, home-manager }: {
         nixosConfigurations = {
           thinknix52 = nixpkgs.lib.nixosSystem {
             system = "x86_64-linux";
             modules = [
               nixos-hardware.nixosModules.lenovo-thinkpad-p52
               ./hosts/thinknix52.nix
               ./users/chrism/user.nix
               home-manager.nixosModules.home-manager {
                 home-manager.useUserPackages = true;
                 home-manager.users.chrism = import ./users/chrism/hm.nix;
               }
             ];
           };
         };
       };

- This bit tells ``nixos-rebuild --flake`` that when it is run on a system with
  the hostname ``thinknix52``, use this ``nixpkgs.lib.nixosSystem``
  configuration::

           thinknix52 = nixpkgs.lib.nixosSystem {
             system = "x86_64-linux";
             modules = [
               nixos-hardware.nixosModules.lenovo-thinkpad-p52
               ./hosts/thinknix52.nix
               ./users/chrism/user.nix
               home-manager.nixosModules.home-manager {
                 home-manager.useUserPackages = true;
                 home-manager.users.chrism = import ./users/chrism/hm.nix;
               }
             ];
           };

- It's important to understand that ``thinknix52`` above represents a
  *hostname*.  The linkage in ``flake.nix`` between the hostname and the
  configuration replaces the older ``/etc/nixos/configuration.nix`` symlink
  linkage and it will not be required anymore.

- In my original ``configuration.nix``, I explicitly fetched a tarball for the
  ``nixos-hardware`` repository and made use of it by importing a Lenovo
  P52-specific configuration from it via an entry in an imports list.  When I
  use flakes, I needn't (and can't) do that.  Instead, the combination of
  ``nixos-hardware.url`` in the inputs and the mention of
  ``nixos-hardware.nixosModules.lenovo-thinkpad-52`` in the modules section of
  the output implies that we want to use that same configuration.

  You can find the flakes-name of your hardware configuration via
  https://github.com/NixOS/nixos-hardware/blob/master/flake.nix .  The
  ``nixos-hardware.nixosModules.`` prepend was cargo culted from
  https://github.com/NixOS/nixos-hardware#using-nix-flakes-support .

  Adding that stuff to ``flake.nix`` meant that I could remove both the
  ``fetchTarball`` of the nixos-hardware repo and the line that imported the
  P52 stuff from it from ``thinknix52.nix``. So this::
  
     { config, pkgs, lib, ... }:

     let
       hw = fetchTarball
         "https://github.com/NixOS/nixos-hardware/archive/master.tar.gz";
     in {
       imports = [
         (import "${hw}/lenovo/thinkpad/p52")
         ../common/pseries.nix
         ../common/encryptedzfs.nix
         ../common/configuration.nix
         ../common/rc505.nix
         ../common/home/chrism.nix
       ];
       ....

  Became this::

     { config, pkgs, lib, ... }:
     {
       imports = [
         ../common/pseries.nix
         ../common/encryptedzfs.nix
         ../common/configuration.nix
         ../common/rc505.nix
         ../common/home/chrism.nix
       ];
       ....

- We now need to appease home-manager to work under the new flakes regime.
  This is a bit more annoying.

- In my non-flakes configuration, I had a single
  ``/etc/nixos/common/home/chrism.nix`` file that contained expressions that
  defined both my ``chrism`` NixOS user and his home manager configuration,
  like this::

    
    { config, pkgs, ... }:

    let
      hm = fetchTarball
        "https://github.com/nix-community/home-manager/archive/release-22.11.tar.gz";
    in {
      imports = [ (import "${hm}/nixos") ];

      nix.extraOptions = ''
        experimental-features = nix-command flakes
        trusted-users = root chrism
      '';

      # Define a user account.
      users.users.chrism = {
        isNormalUser = true;
        initialPassword = "pw321";
        extraGroups =
          [ "wheel" "networkmanager" "audio" "docker" "nixconfig" "dialout" ];
        openssh = {
          authorizedKeys.keys = [
            "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOLXUsGqUIEMfcXoIiiItmGNqOucJjx5D6ZEE3KgLKYV ednesia"
          ];
        };
      };

      home-manager.users.chrism = { pkgs, config, ... }: {

        home.packages = with pkgs; [ keybase-gui ];
        home.stateVersion = "22.05";

      ...

- As with our nixos-hardware configuration, we are fetching a tarball for
  home-manager inside this file, which isn't going to fly under the flakes
  regime.  Instead, we need to feed our home-manager configuration to a
  function in our ``modules`` list in our flake outputs::

       outputs = { self, nixpkgs, nix, nixos-hardware, home-manager }: {
         nixosConfigurations = {
           thinknix52 = nixpkgs.lib.nixosSystem {
             system = "x86_64-linux";
             modules = [
               nixos-hardware.nixosModules.lenovo-thinkpad-p52
               ./hosts/thinknix52.nix
               ./users/chrism/user.nix
               home-manager.nixosModules.home-manager {
                 home-manager.useUserPackages = true;
                 home-manager.users.chrism = import ./users/chrism/hm.nix;
               }
             ];
           };
         };
       };

- I moved things around in the repository, such that I decoupled the
  NixOS-related things about my ``chrism`` user (e.g. ``users.users.chrism =
  {....``) from the home-manager related things about my chrism user
  (e.g. ``home-manager.users.chrism = ...``).

  I put the former in ``/etc/nixos/users/chrism/user.nix`` and the latter in
  ``/etc/nixos/users/chrism/hm.nix``.  In other words, I moved the
  NixOS-related stuff in ``/etc/nixos/common/home/chrism.nix`` to
  ``/etc/nixos/users/chrism/user.nix`` and the home-manager-related to stuff in
  ``/etc/nixos/common/home/chrism.nix`` to ``/etc/nixos/users/chrism/hm.nix``.
  Then I deleted ``/etc/nixos/common/home/chrism.nix``.

- As a result, ``/etc/nixos/users/chrism/user.nix`` in the new flakes regime
  looks like this::

    { config, pkgs, ... }:

    {
    nix.extraOptions = ''
      experimental-features = nix-command flakes
      trusted-users = root chrism
    '';

    # Define a user account.
    users.users.chrism = {
      isNormalUser = true;
      initialPassword = "pw321";
      extraGroups =
        [ "wheel" "networkmanager" "audio" "docker" "nixconfig" "dialout" ];
      openssh = {
        authorizedKeys.keys = [
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOLXUsGqUIEMfcXoIiiItmGNqOucJjx5D6ZEE3KgLKYV ednesia"
        ];
      };
    };
    }

- And ``/etc/nixos/users/chrism/hm.nix`` starts out like this::

    { config, pkgs, home-manager, ... }:

    {
      home.packages = with pkgs; [ keybase-gui ];
      ... a bunch more configuration here ...

- This splitting was in service of being able to do::

    modules = [
      ...
      home-manager.nixosModules.home-manager {
        home-manager.useUserPackages = true;
        home-manager.users.chrism = import ./users/chrism/hm.nix;
      }
      ...

  And, separately in the modules list::

    
    modules = [
      ...
      ./users/chrism/user.nix
      ...

- I removed the import of ``/etc/nixos/common/home/chrism.nix`` from
  ``/etc/nixos/hosts/thinknix52.nix` such that this::

       imports = [
         ../common/pseries.nix
         ../common/encryptedzfs.nix
         ../common/configuration.nix
         ../common/rc505.nix
         ../common/home/chrism.nix
       ];

  Became this::
    
       imports = [
         ../common/pseries.nix
         ../common/encryptedzfs.nix
         ../common/configuration.nix
         ../common/rc505.nix
.       ];

    
      
- We completely got rid of the fetchTarball for the home-manager repository, it
  exists nowhere now, but is implied by ``home-manager.url =
  "github:nix-community/home-manager/release-22.11";`` in the inputs.

- With all that done, I tried to ``nixos-rebuild switch --flake``, and it
  actually started to work!  My ``/etc/nixos/configuration.nix`` file was now
  completely ignored, and ``/etc/nixos/flake.nix`` had taken over.

- But I had one other small issue to figure out.  My rebuild would fail with an
  error something like this::

   error: 'builtins.storePath' is not allowed in pure evaluation mode

  More detail at https://github.com/nix-community/home-manager/issues/2409

- This turned out to be due to a laziness I had succumbed to before.  At the
  time I installed NixOS, the ``olive-editor`` derivation was failing to build
  properly, so I couldn't use Olive Video Editor without some trickery.  I
  found an old working derivation and installed it, then just pointed to my
  *own nix store* as its source in my NixOS ``environment.systemPackages``
  list.::
  
    environment.systemPackages = with pkgs; [
      ...
      wakeonlan
      /nix/store/4nq5wfa01vq6x00q8k777qhf47bp2wd4-olive-editor-0.1.2
      cachix
      ...

- Happily, the olive-editor NixOS build had been fixed in the meantime since I
  I first installed NixOS, so I replaced this with::
    
    environment.systemPackages = with pkgs; [
      ...
      wakeonlan
      olive-editor
      cachix
      ...

  And things now worked.
  
- I could now delete both ``/etc/nixos/configuration.nix`` and remove the
  ``nixos`` channel from my root user (e.g. ``nix-channel --remove nixos``).
  Now when I want to upgrade to 23.05, I should just be able to change the
  respective ``nixpkgs`` and ``home-manager`` URLs in ``/etc/nixos/flake.nix``
  to those reflective of 23.05 and rebuild.

- I repeated the process of changing all of my configurations in
  ``/etc/nixos/hosts`` to match something similar to
  ``/etc/nixos/hosts/thinknix52.nix``.  And now I am switched to flakes.

  
