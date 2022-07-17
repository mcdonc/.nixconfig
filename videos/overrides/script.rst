NixOS 26: Overriding Simple Values in Nix Configuration
=======================================================

- Companion to video at https://youtu.be/bbxJH21qXFE

- See the other videos in this series by visiting the playlist at
  https://www.youtube.com/playlist?list=PLa01scHy0YEmg8trm421aYq4OtPD8u1SN

Video Script
------------

- Inspired by https://discourse.nixos.org/t/what-does-mkdefault-do-exactly/9028

- Within
  https://github.com/NixOS/nixos-hardware/blob/master/lenovo/thinkpad/p53/default.nix
  there is a use of "lib.mkDefault"::
    
   services.throttled.enable = lib.mkDefault true;

- Pop quiz: what do you do if you have a P53, you want to use the rest of the
  configuration implied by the ``p53`` profile in the ``nixos-hardware``
  repository but you don't want the ``throttled`` service to run?

- Answer: anywhere in your ``/etc/nixos/configuration.nix`` or in any file
  included in it, put::

    services.throttled.enable = false;

- But why does this work?  The use of ``lib.mkDefault`` in the ``p53`` profile
  is a clue.

- What does ``lib.mkDefault`` do?  Check out
  https://github.com/NixOS/nixpkgs/blob/9dfcba812aa0f4dc374acfe0600d591885f4e274/lib/modules.nix#L652 ::

     mkDefault = mkOverride 1000; # used in config sections of non-user modules to set a default

- ``mkDefault`` is a function that takes a single argument: the value, and
  assigns the value a priority of 1000.  When Nix parses configuration, it
  reads all the values from every included module into a single namespace.
  When two modules define the same name with different values, it is by their
  *priority* that they are deconflicted.

- ``mkOverride`` is a function that takes two arguments: a priority and a
  value.  It assigns that value the given priority to be used at deconflict
  time.

- ``services.throttled.enable = lib.mkDefault true;`` is just a nicer spelling
  of ``services.throttled.enable = lib.mkOverride 1000 true;``

- Values with lower priorities supersede values with higher priorities.

- Values that are not run through ``mkDefault`` or ``mkOverride`` or any other
  various ``mk...`` function that assign a value a priority are given a
  default priority, which is 100.  Thus this::

    services.throttled.enable = false;

  Is just a nicer spelling of::

    services.throttled.enable = lib.mkOverride 100 false;

- It is only when two keys have differing values but the same priority that Nix
  will complain at rebuild time and ask you to intervene.

- Let's say the ``p53`` profile author forgot the ``lib.mkDefault`` in front of
  his assignment of true to ``services.throttled.enable`` and he just said::

    services.throttled.enable = true;

- You still don't want to run ``throttled``.  What can you do?::

    services.throttled.enable = lib.mkForce false;

- ``lib.mkForce false;`` is just a nicer spelling of ``lib.mkOverride 50 false;``.

- Not discussed: How are the values in attribute sets of modules merged?  This
  is a whole other topic that I don't yet understand.

- For example, within
  https://github.com/mcdonc/nixos-hardware/blob/master/common/gpu/intel.nix#L10 ::

      hardware.opengl.extraPackages = with pkgs; [
        vaapiIntel
        libvdpau-va-gl
        intel-media-driver
      ];

- I *think* you can *extend* this list of extra packages in your own local
  config without doing anything particularly special::

     hardware.opengl.extraPackages = with pkgs; [
        vaapiVdpau
     ];

- But I'm not yet sure.

  
