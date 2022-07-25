NixOS 39: All About Modules
===========================

- Companion to video at ...
  
- See the other videos in this series by visiting the playlist at
  https://www.youtube.com/playlist?list=PLa01scHy0YEmg8trm421aYq4OtPD8u1SN

Video Script
------------

- Let's take a look at the Nix wiki to see what it says about modules:
  https://nixos.wiki/wiki/Module .

- When a module accepts an attribute set, it becomes a function::

    {foo, bar}:
    {
    }

- About the ellipsis in the function arguments The ellipsis allows the function
  to accept any number of arguments other than those specified, which it throws
  away.  In NixOS, appears to be a relatively useless feature, because the
  values passed to the argument function are matched automagically anyway.  Or,
  rather, they aren't cared about until they are accessed.  E.g. ::

    { pkgs, ajsfhkjasfdjkasfkjasfk}:
    {
    }


- imports = [], options = {}, config = {}::

    { config, pkgs, ... }:
    {
      imports =
        [ paths of other modules
        ];

      options = {
        option declarations
      };

      config = {
        option definitions
      };
    }

- Convenience spelling: https://nixos.org/manual/nixos/stable/index.html#ex-module-syntax    
    
  Will work just fine?  https://nixos.org/manual/nixos/stable/#sec-nix-syntax-summary

- THe NixOS manual mention ``nixos-option`.  No longer appears to exist.

- ``nix-repl``.
