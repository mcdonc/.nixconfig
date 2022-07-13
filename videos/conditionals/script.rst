NixOS 28: Conditionalizing Simple Values In Configuration
=========================================================

- Companion to video at ...

- See the other videos in this series by visiting the playlist at
  https://www.youtube.com/playlist?list=PLa01scHy0YEmg8trm421aYq4OtPD8u1SN

Video Script
------------

- Nix allows you to conditionalize the value of one option on the value of
  another using ``lib.mkIf``.  Must be called with a boolean value.

- Resolution appears to be a two-pass thing.

- First, the unconditional values are resolved.

- Then, the conditional values are resolved, in my imagination, in some sort of
  dependency tree order.

- You might imagine you can do this::

    # fix suspend/resume screen corruption in sync mode
    hardware.nvidia.powerManagement.enable =
       lib.mkIf config.hardware.nvidia.prime.sync.enable lib.mkDefault true;

- But nope::

    error: attempt to call something which is not a function but a set

           at /home/chrism/projects/nixos-hardware/lenovo/thinkpad/p52/default.nix:29:6:

               28|   hardware.nvidia.powerManagement.enable =
               29|      lib.mkIf config.hardware.nvidia.prime.sync.enable lib.mkDefault true;
                 |      ^
               30|
    (use '--show-trace' to show detailed location information)
    
- You need to break ``enable`` off::

    # fix suspend/resume screen corruption in sync mode
    hardware.nvidia.powerManagement =
      lib.mkIf config.hardware.nvidia.prime.sync.enable {
        enable = lib.mkDefault true;
      };
    
-  What happens if two conditions have a circular dependency on each other?::

     # fix suspend/resume screen corruption in sync mode
     hardware.nvidia.powerManagement =
       lib.mkIf config.hardware.nvidia.modesetting.enable {
         enable = lib.mkDefault true;
       };
     
     # fix screen tearing in sync mode
     hardware.nvidia.modesetting =
       lib.mkIf config.hardware.nvidia.powerManagement.enable {
         enable = lib.mkDefault true;
       };
     
- Infinite recursion detection::
    
      building Nix...
      building the system configuration...
      error: infinite recursion encountered

             at /nix/var/nix/profiles/per-user/root/channels/nixos/lib/modules.nix:746:9:

                745|     in warnDeprecation opt //
                746|       { value = builtins.addErrorContext "while evaluating the option `${showOption loc}':" value;
                   |         ^
                747|         inherit (res.defsFinal') highestPrio;
      (use '--show-trace' to show detailed location information)
     
