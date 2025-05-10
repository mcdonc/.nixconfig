NixOS 99: Modularizing Your NixOS Config as a Mere Mortal
=========================================================

- Companion to video at ...
  
- See the other videos in this series by visiting the playlist at
  https://www.youtube.com/playlist?list=PLa01scHy0YEmg8trm421aYq4OtPD8u1SN

Video Script
------------

This video was inspired by the `"Modularizing Your NixOS Config" chapter of the
NixOS & Flakes Book
<https://nixos-and-flakes.thiscute.world/nixos-with-flakes/modularize-the-configuration>`_
by ryan4yin.

I really wish I had read that before making a hash of things when I first
started out with NixOS.  No docs designed to help people who didn't really care
much about Nix itself, but were keenly interested in NixOS seemed to exist
then, and it seems to be hard to find them even now.  I won't be talking about
the beauty of purely functional languages or laziness or component stores or
PhD theses in this video.  We'll stick to the totally practical.

This video extends the the spirit of Ryan's chapter with explanations of some
of the other things that confused the heck out of me when I first started.

Some of it even reveals magic of NixOS that is not obvious but is glorious.

Imports and The Configuration Namespace
---------------------------------------

When you first start out with NixOS, all of your important configuration will
be in the ``configuration.nix`` file.  It's easy to reason about this: all the
stuff is in one place, and you just kinda add and change configuration options
within this one file.  It's obviously "one namespace".

But eventually you may want to modularize your configuration.  For example, the
sheer length of your ``configuration.nix`` might make you uncomfortable, and
you'd like to split your configuration into multiple files to make it easier to
read.  Or maybe you'd like to configure more than one system from the same set
of NixOS files, and different systems have different configuration, which you'd
like to represent as a separate file for each system.

NixOS allows for this by the use of "imports".

In NixOS, the most straightforward way to import code from another file is to
jam it into the ``imports`` list within ``configuration.nix``.  Let's imagine
you have this ``configuration.nix``:

.. code-block:: nix

  # configuration.nix
  { config, lib, pkgs, ... }:
  {
    boot.loader.systemd-boot.enable = true;
    boot.loader.efi.canTouchEfiVariables = true;
    networking.networkmanager.enable = true;
    users.users.chrism = {
      initialPassword = "123";
      isNormalUser = true;
      extraGroups = [ "wheel" ];
    };
    environment.systemPackages = with pkgs; [ vim ];
    environment.shellInit = ''export PS1="\u@\h:\w\$ "'';
    system.stateVersion = "25.05";
  }
                
Let's say that you want to keep the definitions of your users in a separate nix
file that lives next to ``configuration.nix`` called ``users.nix``.  You can
remove the ``users.users.chrism`` "attribute set" (we'll talk about what that
means in a bit) from ``configuration.nix`` and put it into a new ``users.nix``
file, then import the ``users.nix`` file from within ``configuration.nix`` by
adding an ``imports`` line:

.. code-block:: nix

  # configuration.nix
  { config, lib, pkgs, ... }:
  {
    imports = [ ./users.nix ];
    boot.loader.systemd-boot.enable = true;
    boot.loader.efi.canTouchEfiVariables = true;
    networking.networkmanager.enable = true;
    environment.systemPackages = with pkgs; [ vim ];
    environment.shellInit = ''export PS1="\u@\h:\w\$ "'';
    system.stateVersion = "25.05";
  }

.. code-block:: nix

  # users.nix
  { config, lib, pkgs, ... }:
  {
    users.users.chrism = {
      initialPassword = "123";
      isNormalUser = true;
      extraGroups = [ "wheel" ];
    };
  }

Even when you use multiple files, NixOS operates against a single global
configuration namespace.  This might be confusing if you're coming from a
modern dynamic scripting language like Ruby or Python, where code in a separate
file usually executes in its own namespace.

When a Nix file is imported by NixOS, it's not like a Python import, where the
definitions of functions and classes in the imported code execute as the result
of the import, but thereafter those functions and classes lay around waiting to
be used in a second step.

Instead, the result of the import is to merge the NixOS configuration returned
by the import into the single NixOS configuration namespace.

A Nix import is more like a C ``#include`` but with some dynamic execution
during the import.  It's not just a textual include.

But note that, to NixOS, the above configuration with the import of
``users.nix`` and the above configuration without the import are *totally
equivalent*.  NixOS doesn't care.  The resulting global namespace is the same
when they are merged.  Use as many or as few files as you like to compose your
configuration.

Attribute Set Syntax
--------------------

Within the following ``configuration.nix``:

.. code-block:: nix

  # configuration.nix
  { config, lib, pkgs, ... }:
  {
    boot.loader.systemd-boot.enable = true;
    boot.loader.efi.canTouchEfiVariables = true;
    networking.networkmanager.enable = true;
    users.users.chrism = {
      initialPassword = "123";
      isNormalUser = true;
      extraGroups = [ "wheel" ];
    };
    environment.systemPackages = with pkgs; [ vim ];
    environment.shellInit = ''export PS1="\u@\h:\w\$ "'';
    system.stateVersion = "25.05";
  }

The following portion is an attribute set:

.. code-block:: nix

  {
    boot.loader.systemd-boot.enable = true;
    boot.loader.efi.canTouchEfiVariables = true;
    # <elided other config options for brevity>
    system.stateVersion = "25.05";
  }

Attribute sets in Nix are like dictionaries in other languages, except they can
be spelled in at least two different ways.

This one line:

.. code-block:: nix

     boot.loader.systemd-boot.enable = true;

Is entirely equivalent to these seven lines:

.. code-block:: nix

     boot = {
       loader = {
         systemd-boot = {
           enable = true;
         };
       };
     };


Nix allows for both in order to make it easy to spell configuration options
without a lot of extra squiggly braces.

You can use the squiggly brace syntax where it makes sense, and the dot-syntax
where it makes sense to you, and you can even combine the two syntaxes.  For
example:

.. code-block:: nix
                
     boot.loader = {
       systemd-boot.enable = true;
       efi.canTouchEfiVariables = true;
     };

Is equivalent to 

.. code-block:: nix
                
     boot = {
       loader = {
         systemd-boot {
           enable = true;
         };
         efi {
           canTouchEfiVariables = true;
         };
       };
     };

As well as:

.. code-block:: nix

     boot.loader.systemd-boot.enable = true;
     boot.loader.efi.canTouchEfiVariables = true;

Detour: The Semicolon and Squiggly Brace Scourge
------------------------------------------------

When you're writing Nix, you might be confused about when you need a semicolon
to terminate a line and when you don't.  Semicolons are used to terminate
*assignment* statements.  That means any time you say ``foo = "bar";`` you need
the assignment to terminate with a semicolon.  It may get particularly
confusing when you're creating an attribute set. 

For example, let's take the following assignment: ``foo = { a = 1;};``.

``a = 1`` is an assignment, and thus must be terminated with a semicolon.
``foo = <the attribute set with "a = 1;" in it>`` is also an assignment, and
must be terminated with a semicolon.  We have two assigments above, so we have
two equal signs and two semicolons.

Confusion about when and when not to use a semicolon is made a little worse by
Nix syntax, and its use of squiggly brackets to mean multiple things, and
NixOS' abundant use of attribute sets.

.. code-block:: nix

  # users.nix
  { config, lib, pkgs, ... }:
  {
    users.users.chrism = {
      initialPassword = "123";
      isNormalUser = true;
      extraGroups = [ "wheel" ];
    };
  }

There are three places that squiggly braces are used in this snippet of code:

- The function argument list.  This file (``users.nix``) is a function by
  virtue of having a function argument list.  The function argument list is
  ``{config, lib, pkgs, ...}:``.

- The value returned by the function .  This function returns an attribute set
  ``{ users.users.chrism = <elided> }``.
  
- The assignment of an attribute set to a configuration option:
  ``users.users.chrism = { <elided> };``.

Nix uses squiggly braces followed by a colon to signify a function.  It uses
squiggly braces *not* followed by a colon to signify an attribute set.

We don't need a semicolon to terminate the function argument list because a
function definition is not an assignment statement.

We don't need a semicolon to terminate the return value of the function (an
attribute set), because it is similarly not part of an assignment statement.
We are just returning the attribute set.

We *do* need a semicolon to terminate the assigment of the
``users.users.chrism`` attribute set, because it is part of an assignment
statement.

But you're a human, not a computer, and the differences here are often hard to
distinguish by a human when you're deep in the weeds.  It is maddening to
``nixos-rebuild`` over and over only to repeatedly have it tell you about a
syntax error despite your best efforts.

So it is almost mandatory to use a code editor that points out syntax errors
interactively when you are editing Nix code.  ``vim`` kinda helps with this via
colorization, but without extensions, it won't detect and point out when you've
forgotten a semicolon or have too many squiggly brackets and so forth.  I use
``emacs`` with ``nix-mode`` and ``flycheck`` and the combination does a pretty
good job of pointing out syntax errors.  There is a Nix mode for VSCode that
also seemed to do a good job while I briefly used it.

It is pretty much madness to edit Nix code without these features.

The Let Block vs. the Return Expression
---------------------------------------

You will often see a ``let .. in`` block before the configuration attribute
set.  For example:

.. code-block:: nix

  # configuration.nix
  { config, lib, pkgs, ... }:
  let
     password = "123";
     groups = [ "wheel" ];
  in
  {
    boot.loader.systemd-boot.enable = true;
    boot.loader.efi.canTouchEfiVariables = true;
    networking.networkmanager.enable = true;
    users.users.chrism = {
      initialPassword = password;
      isNormalUser = true;
      extraGroups = groups;
    };
    environment.systemPackages = with pkgs; [ vim ];
    environment.shellInit = ''export PS1="\u@\h:\w\$ "'';
    system.stateVersion = "25.05";
  }

``let .. in`` allows you to define expressions that can be used within the
configuration.  In fact, a ``let .. in`` block is the *only* place you can
define arbitrary expressions to be used elsewhere in the configuration.  You
can't create a variable within the configuration attribute set itself.  For
example, this won't work:

.. code-block:: nix

  # configuration.nix
  { config, lib, pkgs, ... }:
  {
    password = "123";
    groups = [ "wheel" ];
    boot.loader.systemd-boot.enable = true;
    boot.loader.efi.canTouchEfiVariables = true;
    networking.networkmanager.enable = true;
    users.users.chrism = {
      initialPassword = password;
      isNormalUser = true;
      extraGroups = groups;
    };
    environment.systemPackages = with pkgs; [ vim ];
    environment.shellInit = ''export PS1="\u@\h:\w\$ "'';
    system.stateVersion = "25.05";
  }

Think of it this way: within the configuration options attribute set (the place
you're setting ``boot.loader`` options and users, and packages, etc), you are
*filling in* predefined slots offered up by NixOS configuration via an
assignment. Neither ``password`` nor ``groups`` is a predefined slot; neither
has any meaning to NixOS itself, and what you're creating in the configuration
must have meaning to NixOS.  ``system.stateVersion``, on the other hand, for
example, *does* have meaning to NixOS, so it is allowed in that place.

``let .. in`` blocks allow you to define variables for reuse within the
configuration options attribute set.  They are the only place you can do this.
They can be used in other places than right above the configuration options
attribute set, but in the interest of keeping things simple, we won't talk
about that here.

Merging
-------

Imported NixOS configuration defined as attribute sets like this will be
*merged* with the attribute set defined in the file doing the importing.
Attributes that share the same root value will be merged together.

For example, if you have this code in your ``configuration.nix``:

.. code-block:: nix
                
     boot = {
       loader = {
         systemd-boot = {
           enable = true;
         };
       };
     };


And in your ``configuration.nix``, you import another file that has this in it:

.. code-block:: nix
                
  boot.loader.efi.canTouchEfiVariables = true;

The resulting ``boot`` attribute set that NixOS will see will be:

.. code-block:: nix

     boot = {
       loader = {
         systemd-boot = {
           enable = true;
         };
         efi = {
           canTouchEfiVariables = true;
         }
       };
     };

Resolving Configuration Conflicts
---------------------------------

Even if imported files have definitions that seemingly conflict with the
configuration options in the file they're being imported from, the Nix module
system will often be able to deconflict them by merging lists, strings, and
attribute sets together in a clever way.

For example, let's say we have:

.. code-block:: nix

  # configuration.nix
  { config, lib, pkgs, ... }:
  {
    imports = [ ./packages.nix ./users.nix];
    boot.loader.systemd-boot.enable = true;
    boot.loader.efi.canTouchEfiVariables = true;
    environment.systemPackages = with pkgs; [ vim ];
  }

.. code-block:: nix

  # packages.nix
  { config, lib, pkgs, ... }:
  {
    environment.systemPackages = with pkgs; [ emacs ];
  }

The important thing to note here is that we have two conflicting definitions of
``environment.systemPackages``, one in each file.

In ``configuration.nix``, we have this definition:

.. code-block:: nix

    environment.systemPackages = with pkgs; [ vim ];

In ``packages.nix``, this one:

.. code-block:: nix

    environment.systemPackages = with pkgs; [ emacs ];

In most configuration systems, you would expect this to not work.  How could
it?  You've given it a conflicting definition for a value.

But Nix is not most configuration systems.  Nix is not only willing to merge
the *keys* of the attribute sets together, but it is also willing to merge the
*values* of members of an attribute set.

When we run ``nixos-rebuild`` against the configuration above, we will wind up
with the equivalent of this in the global configuration namespace:

.. code-block:: nix

    environment.systemPackages = with pkgs; [ vim emacs ];

Un-sugared, it would look like:

.. code-block:: nix

   environment.systemPackages = [ pkgs.vim pkgs.emacs ];

Configuration options in NixOS are typed.  ``environment.systemPackages`` is a
configuration value that is of the type list.  When two files have conflicting
definitions for the values in the same list, they are merged together during
Nix evaluation if the configuration option allows for it.
``environment.systemPackages`` does allow for it.

``mkForce`` / ``mkDefault`` / ``mkOverride``
--------------------------------------------

Pretty easy for lists.  But what about boolean values?  Surely a thing can't be
both true and false.  Let's take the same configurations but modify things such
that we're including a file that changes a boolean value instead of a list:

.. code-block:: nix

  # configuration.nix
  { config, lib, pkgs, ... }:
  {
    imports = [ ./networking.nix ./users.nix ];
    boot.loader.systemd-boot.enable = true;
    boot.loader.efi.canTouchEfiVariables = true;
    networking.networkmanager.enable = true;
  }

.. code-block:: nix

  # networking.nix
  { config, lib, pkgs, ... }:
  {
    networking.networkmanager.enable = false;
  }

Indeed, when we try to run ``nixos-rebuild switch`` against this configuration
it will complain at us bitterly about two definitions for
``networking.networkmanager.enable`` conflicting.

But we can fix it by using either ``lib.mkForce`` or ``lib.mkDefault``, which
are functions that tell Nix the relative precedence of the value.

Here's how we can fix it using ``lib.mkDefault``:

.. code-block:: nix

  # configuration.nix
  { config, lib, pkgs, ... }:
  {
    imports = [ ./networking.nix ./users.nix ];
    boot.loader.systemd-boot.enable = true;
    boot.loader.efi.canTouchEfiVariables = true;
    networking.networkmanager.enable = lib.mkDefault true;
  }

.. code-block:: nix

  # networking.nix
  { config, lib, pkgs, ... }:
  {
    networking.networkmanager.enable = false;
  }

Note that we only changed ``configuration.nix``, adding ``lib.mkDefault``
before ``true`` on the networkmanager enable line.  This tells NixOS that this
is the *default* value for that key, so it has lower precedence than values set
without ``lib.mkDefault``.  If any import sets it to a different value, it will
use that value.  Since ``networking.nix`` sets the value to ``false``, it will
be false.

Here's how we can fix it using ``lib.mkForce``:

.. code-block:: nix

  # configuration.nix
  { config, lib, pkgs, ... }:
  {
    imports = [ ./networking.nix ./users.nix ];
    boot.loader.systemd-boot.enable = true;
    boot.loader.efi.canTouchEfiVariables = true;
    networking.networkmanager.enable = true;
  }

.. code-block:: nix

  # networking.nix
  { config, lib, pkgs, ... }:
  {
    networking.networkmanager.enable = lib.mkForce false;
  }

In the above configuration, we used ``lib.mkForce`` before the value of the
network manager enable ``false`` value.  This tells Nix that the precedence of
this value is higher than most other definitions of the same value.  Since the
value in ``configuration.nix`` is not forced, the value in ``networking.nix``
has higher precedence, and is therefore ``false``.

These values are part of an ordering system based on a Nix function called
``lib.mkOverride``, which is a more verbose way to spell ``mkDefault`` and
``mkForce`` that uses specific integer values for each.

``mkBefore`` / ``mkAfter`` / ``mkOrder``
----------------------------------------

Some Nix configuration string values, like ``environment.shellInit``, can
also be influenced by Nix functions named ``lib.mkBefore``, ``lib.mkAfter``,
and ``lib.mkOrder``.

For example, let's try to set two differing string values for
``environment.shellInit`` within our two files:

.. code-block:: nix

  # configuration.nix
  { config, lib, pkgs, ... }:
  {
    imports = [ ./shell.nix ./users.nix ];
    boot.loader.systemd-boot.enable = true;
    boot.loader.efi.canTouchEfiVariables = true;
    environment.shellInit = ''export MYVAR="default"'';
  }

.. code-block:: nix

  # shell.nix
  { config, lib, pkgs, ... }:
  {
    environment.shellInit = ''export MYVAR="from shell.nix"'';
  }

When we fire up our system, we will find that nothing conflicted, even though
the two files have differing values for ``environment.shellInit``.  Why?  It
concatenated the two values and added them together, then added that result to
the shell init.

When we fire up the system, we'll see that the MYVAR environment variable is
set to ``default``.  This is because the file modified by
``environment.shellInit``, ``/etc/profile`` has this in it:

.. code-block:: bash
                
  export MYVAR="from shell.nix"
  export MYVAR="default"

It added both lines to the file, but in an order such that the value in
``configuration.nix`` "won".

We can influence this using ``lib.mkAfter``:

.. code-block:: nix

  # configuration.nix
  { config, lib, pkgs, ... }:
  {
    imports = [ ./shell.nix ./users.nix ];
    boot.loader.systemd-boot.enable = true;
    boot.loader.efi.canTouchEfiVariables = true;
    environment.shellInit = ''export MYVAR="default"'';
  }

.. code-block:: nix

  # shell.nix
  { config, lib, pkgs, ... }:
  {
    environment.shellInit = lib.mkAfter ''export MYVAR="from shell.nix"'';
  }

With the ``lib.mkAfter`` in place, when we fire up the system, we will see that
the ``/etc/profile`` now has this in it:

.. code-block:: bash
                
  export MYVAR="default"
  export MYVAR="from shell.nix"

In this way, we can influence the order that string fields that are willing to
participate will be concatenated together.

``lib.mkBefore`` is the inverse of ``lib.mkAfter`` and ``lib.mkOrder`` is the
function that ``lib.mkBefore`` and ``lib.mkAfter`` are based on that accepts an
integer priority as well as the value.
