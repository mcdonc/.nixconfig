NixOS 32: Using An Overlay
==========================

- Companion to video at ...

- See the other videos in this series by visiting the playlist at
  https://www.youtube.com/playlist?list=PLa01scHy0YEmg8trm421aYq4OtPD8u1SN

Video Script
------------

- Overlays let you override the values used by Nix modules that define
  derivations (usually from ``nixpkgs``).

- You can change the result of just about any derivation: but changing the version and
  applying patches are usually what I want to do.

- I will show changing the source revision of something.  I won't show *adding* a
  patch, but I'll show something that already uses a patch.

- Let's install ardour.  Latest version in nixpkgs is 6.9.::

     environment.systemPackages = with pkgs; [
        # ....
        ardour
        # .....
     ];
    

- But when you start it, it won't quit.

- Research shows that this is a known issue, and has been fixed in the repo (it
  hasn't).

- But we can use it as an example anyway.

- Take a look at
  https://github.com/NixOS/nixpkgs/blob/master/pkgs/applications/audio/ardour/default.nix ::
      version = "6.9";

      src = fetchgit {
        url = "git://git.ardour.org/ardour/ardour.git";
        rev = version;
        sha256 = "0vlcbd70y0an881zv87kc3akmaiz4w7whsy3yaiiqqjww35jg1mm";
      };

      patches = [
      # AS=as in the environment causes build failure https://tracker.ardour.org/view.php?id=8096
          ./as-flags.patch
      ];

- Take a look at "as-flags.patch".

- Check out ardour::

      git clone git://git.ardour.org/ardour/ardour.git

- We want to use the latest master revision of Ardour instead of the ::

    $ git rev-parse HEAD
    4556f55d8ed84b07e6fe81f3f6a8021c414801bf

- Inside our configuration.nix::

     nixpkgs.overlays = [
       (self: super: {
         ardour-git = super.ardour.overrideAttrs (old: {
           src = super.fetchgit {
             url = "git://git.ardour.org/ardour/ardour.git";
             # master on 7/17/2022
             rev = "4556f55d8ed84b07e6fe81f3f6a8021c414801bf";
             sha256="sha256-4tsV6KV3XXZknQe8C+521fIIWoAuN2lvzvv2Ecp8SQo=";
           };
         });
       })
     ];

     environment.systemPackages = with pkgs; [
        # ....
        #ardour
        ardour-git
        # .....
     ];
        
- It will build, eventually, but I'm going to cancel the build because I've
  already put up a cached copy on my cachix.org account.  When I include my
  cachix config, it will pull the cached copy instead of trying to rebuild from
  source.

- Still no worky, but it was worth a shot.
