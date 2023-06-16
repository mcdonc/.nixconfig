NixOS 43: Overriding Packages That are Within Attribute Sets
============================================================

- Companion to video at

- See the other videos in this series by visiting the playlist at
  https://www.youtube.com/playlist?list=PLa01scHy0YEmg8trm421aYq4OtPD8u1SN

Video Script
------------

- Thanks to the various folks in the NixOS Matrix room for help with this.

- The NixOS wiki describes in a passage at
  https://nixos.wiki/wiki/Overlays#Overriding_a_package_inside_an_attribute_set
  claiming to override the attributes of a package within an attribute set, you
  should create an overlay something like::

   final: prev: {
   vimPlugins = prev.vimPlugins.extend (final': prev': {
     indent-blankline-nvim-lua = prev.callPackage ../packages/indent-blankline-nvim-lua { };
   });
   }

  This would ostensibly override (or add) the
  ``vimPlugins.indent-blankline-nvim-lua`` Vim plugin using a derivation you
  define in the ``../packages/indent-blankline-nvim-lua.nix`` file.

- But this only works for packages in attribute sets that have been blessed by
  a library function named ``lib.makeExtensible`` (or so I understand, anyway,
  please correct in comments if not so).  Some package-containing attribute
  sets are not blessed this way.  The symptom you'll see when you try to use
  something like the above in that situation is something along the lines of
  ``no such attribute "extend."``

- Instead of this, you can use a combination of the attrset merge operator
  (``//``) and ``overrideAttrs`` of the materialized derivation something like
  this::

    final: prev: {
      obs-studio-plugins = prev.obs-studio-plugins // {
        obs-backgroundremoval =
          prev.obs-studio-plugins.obs-backgroundremoval.overrideAttrs (old: {
            version = "0.5.16";
            src = prev.fetchFromGitHub {
              owner = "royshil";
              repo = "obs-backgroundremoval";
              rev = "v0.5.16";
              hash = "sha256-Bq0Lfn+e9A1P7ZubA65nWksFZAeu5C8NvT36dG5N2Ug=";
            };
          });
      };
    };
