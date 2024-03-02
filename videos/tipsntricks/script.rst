==============================
NixOS #75: Nix Tips and Tricks
==============================

These are some tips 'n tricks related to Nix that I've learned over time.

See a Summary of Changes After ``nixos-rebuild``
------------------------------------------------

Stolen from https://chattingdarkly.org/@lhf@fosstodon.org/110661879831891580

.. code-block:: nix

    system.activationScripts.diff = {
      supportsDryActivation = true;
      text = ''
        ${pkgs.nvd}/bin/nvd --nix-bin-dir=${pkgs.nix}/bin diff \
             /run/current-system "$systemConfig"
      '';
    };

Then::

    nixos-rebuild switch

Will show (e.g.)::

  [R-]  #1  sops  3.8.1
  Closure size: 4195 -> 4194 (12 paths added, 13 paths removed, delta -1, disk usage -21.4MiB).

Use ``nix-tree`` to See What Depends on What
--------------------------------------------

``nix-tree`` (https://github.com/utdemir/nix-tree) is a TUI tool that allows
you to see the dependency graph of any derivation ::

    nix-tree /nix/store/yb5k3n56ywpng5d41bd02yfwwppbdyjw-python3-3.11.7

Type "/" to search.


Use ``nix-du`` to See What's Consuming Disk Space
-------------------------------------------------

``nix-du`` is a tool that produces a Graphviz file showing disk space consumption of derivation realizations (https://github.com/symphorien/nix-du).

Ensure you have ``graphviz`` and ``nix-du`` in your
``environment.systemPackages``, then::

  nix-du -s=500MB | dot -Tpng > store.png

See Which Derivation Supplies a File
------------------------------------
  
``nix-index`` is a tool that indexes your system and tells you which
derivations provide a particular file or pattern of files.  You run
``nix-index`` and then a subsequent run of ``nix-locate`` finds the
derivation::

    $ nix-index
    $ nix-locate libc.so.6

Requires ``nix-index`` in ``environment.systemPackages``.

Pin ``nixpkgs`` in Flakes Registry to the Lockfile Version
----------------------------------------------------------

Add an item for ``nixpkgs`` to the flakes registry that matches the one in your
NixOS configuration (via
https://dataswamp.org/~solene/2022-07-20-nixos-flakes-command-sync-with-system.html).

Without::

    $ nix registry list|grep nixpkgs
    global flake:nixpkgs github:NixOS/nixpkgs/nixpkgs-unstable

After adding this bit to your NixOS configuration ("inputs" should come from
your ``flake.nix`` in ``specialArgs``):

  .. code-block:: nix

      { inputs, ...}:
      {
      nix.registry = {
        nixpkgs.flake = inputs.nixpkgs;
      };
      }

With::

    $ nix registry list|grep nixpkgs
    global flake:nixpkgs github:NixOS/nixpkgs/nixpkgs-unstable
    system flake:nixpkgs path:/nix/store/52yawfmb2rz0sm07px5zcrgv3y78v27v-source?lastModified=1708831307&narHash=sha256-0iL/DuGjiUeck1zEaL%2BaIe2WvA3/cVhp/SlmTcOZXH4%3D&rev=5bf1cadb72ab4e77cb0b700dab76bcdaf88f706b

Adds the ``system flake:nixpkgs`` What does system mean?  From ``nix registry
--help``::

     There are multiple registries. These are, in order from lowest to highest
     precedence:

     · The global registry, which is a file downloaded from the URL specified by
       the setting flake-registry. It is cached locally and updated
       automatically when it's older than tarball-ttl seconds. The default
       global registry is kept in a GitHub repository.

     · The system registry, which is shared by all users. The default location
       is /etc/nix/registry.json. On NixOS, the system registry can be
       specified using the NixOS option nix.registry.

Also: won't fetch ``nixpkgs-unstable`` for every ``nix shell`` / ``nix run``,
it'll just use the version of ``nixpkgs`` you've already downloaded.
    
This will be the default soon in Nix.  See
https://chattingdarkly.org/@picnoir@social.alternativebit.fr/112002571368237940
and https://github.com/NixOS/nixpkgs/pull/254405.

Sync the ``nixpkgs`` Input Between ``nix-build`` / ``nix build`` and ``nix-shell``/ ``nix shell``
-------------------------------------------------------------------------------------------------

After adding this bit to your NixOS configuration ("inputs" should come from
your ``flake.nix`` in ``specialArgs``):

.. code-block:: nix

    {inputs, ...}:
    {
    nix.nixPath = [ "nixpkgs=${inputs.nixpkgs}" ];
    }

``nix-shell`` will use the same ``nixpkgs`` version as ``nix shell`` and
``nix-build`` will use the same ``nixpkgs`` version as ``nix build``.

The PR mentioned in the last section also handles this; it will be the default
soon enough.

Use Flakes in the Nix REPL
--------------------------

Use the ``repl-flake`` experimental feature

.. code-block:: nix

  {
  nix.settings.experimental-features = "nix-command flakes repl-flake";
  }

Now you can consult a flake when starting ``nix-repl``.::

  $ cd /etc/nixos
  $ nix repl ".#"
  Welcome to Nix 2.18.1. Type :? for help.

  warning: Git tree '/etc/nixos' is dirty
  Loading installable 'git+file:///etc/nixos#'...
  Added 1 variables.
  nix-repl> :lf .
  warning: Git tree '/etc/nixos' is dirty
  Added 12 variables.

E.g. ``nixosConfigurations.optinix.config.hardware.cpu.intel.updateMicrocode``.

Before this, the way I loaded a flake was::
  
  f = builtins.getFlake "git+file://${builtins.toString ./.}"
  
This will be the default soon enough: https://github.com/NixOS/nix/issues/10103

``nixos-repl``
--------------

I usually mostly want to use the REPL to inspect the ``pkgs`` namespace.  It's
convenient to just have that loaded right off the rip:

.. code-block:: nix

   nixos-repl = pkgs.writeScriptBin "nixos-repl" ''
     #!/usr/bin/env ${pkgs.expect}/bin/expect
     set timeout 120
     spawn -noecho nix --extra-experimental-features repl-flake repl nixpkgs
     expect "nix-repl> " {
       send ":a builtins\n"
       send "pkgs = legacyPackages.${system}\n"
       interact
     }
   '';

Now::

  $ nixos-repl
  Welcome to Nix 2.18.1. Type :? for help.

  Loading installable 'flake:nixpkgs#'...
  Added 5 variables.
  nix-repl> :a builtins
  Added 115 variables.

  nix-repl> pkgs = legacyPackages.x86_64-linux
  
  nix-repl> pkgs.linux<TAB>
