NixOS 50: Replacing Overlays in a Flakes-Based Config
=====================================================

- Companion to video at https://youtu.be/IoeCzw22SkI

- This text script available via link in the video description.

- See the other videos in this series by visiting the playlist at
  https://www.youtube.com/playlist?list=PLa01scHy0YEmg8trm421aYq4OtPD8u1SN

Overview
--------

- Nix overlays are most typically used to gain access to older or newer
  revisions of ``nixpkgs`` packages.  If you want, say, the most recent version
  of ``cmake`` (from the unstable branch of nixpkgs).  Or an older version of
  ``olive-editor`` (from the 22.11 branch of nixpkgs).

- It is possible to disuse overlays in your Nix configuration pretty easily if
  you use flakes.

- It's not really necessary to disuse overlays, they work fine.  But we'll
  learn how to pass flake inputs and derivatives thereof down to our "normal"
  config modules without using overlays, in a way that will probably feel more
  natural than attaching random stuff to ``pkgs`` (despite some arcane
  spelling).

Overlays
--------

- The ``overlay-nixpkgs`` overlay below allows us to access
  ``pkgs.r2211.<anypackage>`` and ``pkgs.unstable.<anypackage>`` within any of
  our configuration modules::

    {
      description = "Chris' Jawns";

      inputs = {
        nixpkgs.url = "github:NixOS/nixpkgs/nixos-23.05";
        nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
        nixos-hardware.url = "github:NixOS/nixos-hardware";
        home-manager.url = "github:nix-community/home-manager/release-23.05";
        nixpkgs-r2211.url = "github:NixOS/nixpkgs/nixos-22.11";
      };

      outputs = { self, nixpkgs, nix, nixos-hardware, home-manager,
                  nixpkgs-r2211, nixpkgs-unstable, agenix }:
        let
          system = "x86_64-linux";
          overlay-nixpkgs = final: prev: {
            r2211 = import nixpkgs-r2211 {
              inherit system;
              config.allowUnfree = true;
            };
            unstable = import nixpkgs-unstable {
              inherit system;
              config.allowUnfree = true;
            };
          };
        in {
          nixosConfigurations = {
            thinknix512 = nixpkgs.lib.nixosSystem {
              inherit system;
              modules = [
                ({ config, pkgs, ... }: {
                    nixpkgs.overlays = [ overlay-nixpkgs ];
                    })
                nixos-hardware.nixosModules.lenovo-thinkpad-p51
                ./users/chrism/user.nix
                ./hosts/thinknix512.nix
                home-manager.nixosModules.home-manager {
                  home-manager.useUserPackages = true;
                  home-manager.users.chrism = import ./users/chrism/hm.nix;
               }
              ];
            };
        };
    }

- The ``r2211`` and ``unstable`` attributes of ``pkgs`` subsequently allow me
  to use ``olive-editor`` from the 22.11 version of nixpkgs and ``cmake`` from
  the unstable version of nixpkgs in my ``configuration.nix``::

      environment.systemPackages = with pkgs; [
        neofetch
        r2211.olive-editor
        unstable.cmake
      ]


- Works fine.

Disusing Overlays
-----------------

- Why?  Well, it's not strictly necessary, if overlays fit your brain, go for
  it.

- But it's often necessary to pass configuration that's in your ``flake.nix``
  down through your configuration stack regardless, and if you use flakes and
  need to do this anyway, there are better ways to do what overlays do.

- We can use the ``specialArgs`` argument to ``nixpkgs.lib.nixosSystem`` to
  pass in whatever we want to downstream modules that will be sent to their
  argument list.

- Here is a changed version of the above which disuses overlays.::

    {
      description = "Chris' Jawns";

      inputs = {
        nixpkgs.url = "github:NixOS/nixpkgs/nixos-23.05";
        nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
        nixos-hardware.url = "github:NixOS/nixos-hardware";
        home-manager.url = "github:nix-community/home-manager/release-23.05";
        nixpkgs-r2211.url = "github:NixOS/nixpkgs/nixos-22.11";
      };

      outputs = { self, nixpkgs, nix, nixos-hardware, home-manager,
           nixpkgs-r2211, nixpkgs-unstable, agenix }@inputs:
        let
          system = "x86_64-linux";
          specialArgs = {
            pkgs-unstable = import nixpkgs-unstable {
              inherit system;
              config.allowUnfree = true;
            };
            pkgs-r2211 = import nixpkgs-r2211 {
              inherit system;
              config.allowUnfree = true;
            };
            inherit nixos-hardware;
            inherit system;
            inherit inputs;
          };

        in {
          nixosConfigurations = {
            thinknix512 = nixpkgs.lib.nixosSystem {
              inherit system;
              inherit specialArgs;
              modules = [
                ./users/chrism/user.nix
                ./hosts/thinknix512.nix
                home-manager.nixosModules.home-manager {
                  home-manager = {
                    useUserPackages = true;
                    users.chrism = import ./users/chrism/hm.nix;
                    extraSpecialArgs = specialArgs;
                  };
                }
              ];
            }
          };
        }

- Note that we got rid of both::

      overlay-nixpkgs = final: prev: {
        r2211 = import nixpkgs-r2211 {
          inherit system;
          config.allowUnfree = true;
        };
        unstable = import nixpkgs-unstable {
          inherit system;
          config.allowUnfree = true;
        };
      };

  And::

      ({ config, pkgs, ... }: {
            nixpkgs.overlays = [ overlay-nixpkgs ];
            })

  Replacing them respectively with::
    
      specialArgs = {
        pkgs-unstable = import nixpkgs-unstable {
          inherit system;
          config.allowUnfree = true;
        };
        pkgs-r2211 = import nixpkgs-r2211 {
          inherit system;
          config.allowUnfree = true;
        };
        inherit nixos-hardware;
        inherit system;
        inherit inputs;
      };

  And::

    inherit specialArgs;

- Note that ``inherit specialArgs;`` is just a shorter way of spelling
  ``specialArgs = specialArgs;``.

- Note that we append ``@inputs`` to our ``outputs`` argument list.  This
  captures all the stuff we pass in to our outputs in a single attribute set.

  We can then pass inputs down via ``specialArgs`` ala::

      specialArgs = {
        pkgs-unstable = import nixpkgs-unstable {
          inherit system;
          config.allowUnfree = true;
        };
        pkgs-r2211 = import nixpkgs-r2211 {
          inherit system;
          config.allowUnfree = true;
        };
        inherit nixos-hardware;
        inherit system;
        inherit inputs;
      };
    
- Some folks pass down "bare" ``inputs`` as ``specialArgs`` but here we do some
  preprocessing by importing the unstable and 22.11 nixpkgs with special flags
  so we needn't do it in downstream modules.  We pass in ``inputs`` as a key
  just in case we need it anyway.

- Our use of ``specialArgs`` adds the following arguments to any imported
  module::

    pkgs-unstable, pkgs-r211, nixos-hardware, system, inputs
      
- In an overlay, all overlaid attributes are attached to ``pkgs``.  But now
  that we've added ``specialArgs`` to our call to ``nixpkgs.lib.nixosSystem``,
  Nix will pass them down directly to our imported modules, and so those
  modules can expect them in their argument lists.

- Using the 22.11 and unstable versions of nixpkgs becomes adding
  ``pkgs-r2211`` and ``pkgs-unstable`` to the arglist of ``configuration.nix``
  and referencing them within our ``environment.systemPackages``::

      { config, pkgs, pkgs-r2211, pkgs-unstable, ... }:

      {
      environment.systemPackages = with pkgs; [
        neofetch
        pkgs-r2211.olive-editor
        pkgs-unstable.cmake
      ]

- Bob, uncle.
