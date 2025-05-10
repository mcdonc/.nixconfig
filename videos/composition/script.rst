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

This video covers some of the same ground as Ryan's chapter, and hopefully
preemptively demystifies for you some of the other things that confused me when
I first started.

I won't be talking about the beauty of purely functional languages or laziness
or component stores or PhD theses in this video because it turns out that NixOS
is pretty great even for utilitarians.

Imports and The Configuration Namespace
---------------------------------------

When you first start out, all of your important configuration will be in the
``configuration.nix`` file.  You add and change configuration options within
it.  It's obviously "one namespace".

But eventually you may want to modularize your configuration.  For example, the
length of your ``configuration.nix`` makes you uncomfortable, and you'd like to
split it into multiple files to make it easier to read.  Or maybe you'd like to
configure more than one system from the same set of NixOS files, and different
systems have slightly different configurations, each of which you'd like to
represent as a Nix file.

NixOS allows for this by the use of "imports".

In NixOS, the most straightforward way to import code from another file is to
jam it into a list defined as ``imports`` within ``configuration.nix``.

Given that we have this ``configuration.nix``:

.. code-block:: nix

  # configuration.nix
  { config, lib, pkgs, ... }:
  {
    boot.loader.systemd-boot.enable = true;
    boot.loader.efi.canTouchEfiVariables = true;
    networking.networkmanager.enable = true;
    users.users.fred = {
      initialPassword = "123";
      isNormalUser = true;
      extraGroups = [ "wheel" ];
    };
    environment.systemPackages = with pkgs; [ vim ];
    environment.shellInit = ''export PS1="\u@\h:\w\$ "'';
    system.stateVersion = "25.05";
  }
                
You've decided that you want to keep the definitions of your users in a
separate file that lives next to ``configuration.nix`` called
``users.nix``.  Ours is not to wonder why.

You can remove the ``users.users.fred`` "attribute set" (we'll talk about
what that means in a bit) from ``configuration.nix`` and put it into a new
``users.nix`` file, then import the ``users.nix`` file from within
``configuration.nix`` by adding an ``imports`` line:

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
    users.users.fred = {
      initialPassword = "123";
      isNormalUser = true;
      extraGroups = [ "wheel" ];
    };
  }

Even when you use multiple files, NixOS operates against a single global
configuration namespace.

This might be confusing if you're a programmer coming from a modern dynamic
scripting language like Python, where code in a separate file usually executes
in its own namespace when "imported".

When a Nix file is imported by NixOS, it's not like a Python import, where the
definitions of functions and classes in the imported code execute as the result
of the import, but thereafter those functions and classes lay around waiting to
be used in a second step.

Instead, the result of the import is to merge the NixOS configuration returned
by the import into the single NixOS configuration namespace.  In this way, a
Nix import is more like a C ``#include`` but with some dynamic execution during
the import, it's not just a textual include.

There is magic happening under the hood of ``imports = []`` here, but as long
as you feed it files that have the same structure as ``configuration.nix``, you
can largely get by ignoring it.

By the way, to NixOS, the above configuration with the import of ``users.nix``
and the above configuration without the import are *totally equivalent*.  NixOS
doesn't care.  The resulting global namespace is the same when they are merged.
So you can use as many or as few files as you like to compose your
configuration, in any organization that fits your brain.

In some of the following code examples, you'll see that I'm importing from a
file named ``./demo.nix`` that I don't include the source for.  This file
defines some stuff that helps me make sure what I'm telling you is not a lie,
but it's unnecessary for real world usage, please try to ignore it.

Attribute Sets
--------------

Within the following ``configuration.nix``:

.. code-block:: nix

  # configuration.nix
  { config, lib, pkgs, ... }:
  {
    boot.loader.systemd-boot.enable = true;
    boot.loader.efi.canTouchEfiVariables = true;
  }

The following portion is an "attribute set":

.. code-block:: nix

  {
    boot.loader.systemd-boot.enable = true;
    boot.loader.efi.canTouchEfiVariables = true;
  }

Attribute sets in Nix are like dictionaries in other languages, except they can
be spelled in at least two different ways.

This one line:

.. code-block:: nix

     boot.loader.systemd-boot.enable = true;

Is equivalent to these seven lines:

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
the assignment to terminate with a semicolon.

It may get particularly confusing when you're creating an attribute set.  For
example, let's take the following assignment:

.. code-block:: nix

  foo = { a = 1;};

``a = 1`` is an assignment, and thus must be terminated with a semicolon.
``foo = { a = 1;}`` is also an assignment, and must be terminated with a
semicolon.  We have two assigments above, so we have two equal signs and two
semicolons.

Confusion about when and when not to use a semicolon is made a little worse by
Nix syntax, and its use of squiggly brackets to mean multiple things, and
NixOS' use of attribute sets.

For example:

.. code-block:: nix

  # users.nix
  { config, lib, pkgs, ... }:
  {
    users.users.fred = {
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
  ``{ users.users.fred = <elided> }``.
  
- The assignment of an attribute set to a configuration option:
  ``users.users.fred = { <elided> };``.

Nix uses squiggly braces followed by a colon to signify a function.  It uses
squiggly braces *not* followed by a colon to signify an attribute set.

We don't need a semicolon to terminate the function argument list because a
function definition is not an assignment statement.  That's why it's not
``{config, lib, pkgs, ... }:;``, for example.

We don't need a semicolon to terminate the return value of the function (an
attribute set), because it is similarly not part of an assignment statement.
We are just returning the attribute set.  That's why it's not:

.. code-block:: nix

  # users.nix
  { config, lib, pkgs, ... }:
  {
    users.users.fred = {
      initialPassword = "123";
      isNormalUser = true;
      extraGroups = [ "wheel" ];
    };
  }; # this semicolon doesn't belong here


We *do* need a semicolon to terminate the assigment of the ``users.users.fred``
attribute set, because it is part of an assignment statement.  That's why it's
not:

.. code-block:: nix

  # users.nix
  { config, lib, pkgs, ... }:
  {
    users.users.fred = {
      initialPassword = "123";
      isNormalUser = true;
      extraGroups = [ "wheel" ];
    } # a semicolon is missing here
  }

These differences are hard to distinguish by a human deep in the weeds.  So it
is almost mandatory to use a code editor that points out syntax errors
interactively when you are editing Nix code.

``vim`` kinda helps with this via colorization, but without extensions, it
won't detect and point out when you've forgotten a semicolon or have too many
squiggly brackets and so forth, except through that colorization.  I'm sure
there are extensions to vim which point out specific syntax errors in Nix code.

I use ``emacs`` with ``nix-mode`` and ``flycheck`` and the combination does a
pretty good job of pointing out syntax errors.

There is also a Nix mode for VSCode that also seemed to do a good job while I
briefly used it.

In any case, it is pretty much madness to edit Nix code without interactive
syntax checking features, so it's time well spent to get those working,
whichever editor you use.

The Let Block vs. the Return Expression
---------------------------------------

You will often see a ``let .. in`` block before the configuration attribute
set within a ``.nix`` file.  For example:

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
    users.users.fred = {
      initialPassword = password;
      isNormalUser = true;
      extraGroups = groups;
    };
  }

A ``let .. in`` block allows you to define variables that can be used within
the configuration.  In fact, a ``let .. in`` block is the *only* place you can
define arbitrary variables to be used elsewhere in the same configuration file.

In particular, you can't create a variable within the configuration attribute
set itself.  For example, this won't work:

.. code-block:: nix

  # configuration.nix
  { config, lib, pkgs, ... }:
  {
    password = "123";
    groups = [ "wheel" ];
    boot.loader.systemd-boot.enable = true;
    boot.loader.efi.canTouchEfiVariables = true;
    users.users.fred = {
      initialPassword = password;
      isNormalUser = true;
      extraGroups = groups;
    };
  }

Why doesn't this work?

It might be helpful to think of it this way: within the configuration options
attribute set (the place you're setting ``boot.loader`` options and ``users``,
and ``evnironment.systemPackages``, etc), you are filling in predefined slots
offered up by NixOS configuration options.

``boot.loader.systemd-boot.enable``, ``boot.loader.efi.canTouchEfiVariables``,
and ``users.users.<name>`` are some of those slots.  They are defined within
NixOS "options" in Nixpkgs, and options have a schema. NixOS checks what you
provide against them when you run ``nixos-rebuild``.  First NixOS composes the
big global attribute set representing the values you've given for specific
options, then it checks those values against the schema when you run
``nixos-rebuild``.

In our example above, neither ``password`` nor ``groups`` fits into a slot
defined by an option in Nixpkgs.  Neither has any meaning to NixOS itself,
so when ``nixos-rebuild`` is run, we will get an error.

So we can't define variables in the attribute set we're returning, instead we
have to define them in the ``let .. in`` block above it.

``let .. in`` blocks can be used in other places than right above the
configuration options attribute set, but we can ignore that for the purposes of
this video.

Merging
-------

Imported NixOS configuration defined as attribute sets will be *merged* with
the attribute set defined in the file doing the importing.  Attributes that
share the same root value will be merged together.

For example, if you have this code in your ``configuration.nix``:

.. code-block:: nix
                
   boot.loader.systemd-boot.enable = true;

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

All the stuff in the attribute set defined in the file doing the importing as
well as the attribute sets of the imported files, transitively, are merged
together into the global configuration.

Resolving Configuration Conflicts
---------------------------------

Imported files will often have definitions that seemingly conflict with the
configuration options in the file they're being imported into. But the NixOS
module system will often be able to deconflict them.

Let's say we have:

.. code-block:: nix

  # configuration.nix
  { config, lib, pkgs, ... }:
  {
    imports = [ ./packages.nix ./demo.nix ];
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

Of note is that we have two conflicting definitions of
``environment.systemPackages``, one in each file.

In ``configuration.nix``, we have this definition:

.. code-block:: nix

    environment.systemPackages = with pkgs; [ vim ];

In ``packages.nix``, this one:

.. code-block:: nix

    environment.systemPackages = with pkgs; [ emacs ];

In most configuration systems, you would expect this to not work because when
it tries to merge the ``environment.systemPackages`` attributes together,
you've given it a conflicting definition for a value, and it won't be able to
cope.

But NixOS is not only willing to merge the *keys* of the attribute sets
together, but it is also willing to merge the *values* of members of an
attribute set.

In this case, it will merge the set of packages represented by
``environment.systemPackages`` into a list that includes both ``emacs`` and
``vim``.

When we run ``nixos-rebuild`` against the configuration above, we will wind up
with the equivalent of this in the global configuration namespace:

.. code-block:: nix

    environment.systemPackages = with pkgs; [ vim emacs ];

Or, un-sugared, it would look like:

.. code-block:: nix

   environment.systemPackages = [ pkgs.vim pkgs.emacs ];

Configuration options in NixOS are typed.  ``environment.systemPackages`` is a
configuration value that is of the type list.  When two files have assigments
to the the same list, their values are are merged together during Nix
evaluation if the configuration option allows for it, which
``environment.systemPackages`` does.

``mkForce`` / ``mkDefault`` / ``mkOverride``
--------------------------------------------

Pretty easy for lists.  But what about boolean values?  A thing can't be both
true and false.

Let's take the same configurations but modify things such that we're including
a file that has a conflict using a boolean value instead of a list:

.. code-block:: nix

  # configuration.nix
  { config, lib, pkgs, ... }:
  {
    imports = [ ./networking.nix ./demo.nix ];
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

And sure enough, when we try to run ``nixos-rebuild switch`` against this
configuration it will complain bitterly about two definitions for
``networking.networkmanager.enable`` conflicting.

But we can fix it by using either ``lib.mkForce`` or ``lib.mkDefault``, which
are functions that can tell Nix the relative precedence of the value of
``networking.networkmanager.enable`` in each of its assignments.

Here's how we can fix it using ``lib.mkDefault``:

.. code-block:: nix

  # configuration.nix
  { config, lib, pkgs, ... }:
  {
    imports = [ ./networking.nix ./demo.nix ];
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
without ``lib.mkDefault``.  If any imported attribute sets it to a different
value, it will use that value.  Since ``networking.nix`` sets the value to
``false``, it will be false.

There's another way we can fix things if someone hasn't had the forethought to
set the default value using ``lib.mkDefault``. Here's how we can fix it using
``lib.mkForce``:

.. code-block:: nix

  # configuration.nix
  { config, lib, pkgs, ... }:
  {
    imports = [ ./networking.nix ./demo.nix ];
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

In the above configuration, we prefixed the value of the
``networking.networkmanager.enable`` value ``false`` with ``lib.mkForce``.
This tells Nix that the precedence of this value is higher than any other
definitions of the same value.  Since the value in ``configuration.nix`` is not
forced, the value in ``networking.nix`` has higher precedence, and is therefore
``false`` in the global configuration after evaluation.

These values are part of an ordering system based on a Nix function called
``lib.mkOverride``, which is a more specific way to spell ``lib.mkDefault`` and
``lib.mkForce`` that uses integer values to signify precedence.  In
practice, it's not common to need to use ``mkOverride`` directly.

``mkBefore`` / ``mkAfter`` / ``mkOrder``
----------------------------------------

Some Nix configuration string values, like ``environment.shellInit``, can
also be influenced by Nix functions named ``lib.mkBefore`` and ``lib.mkAfter``.

For example, let's try to set two differing string values for
``environment.shellInit`` within two files:

.. code-block:: nix

  # configuration.nix
  { config, lib, pkgs, ... }:
  {
    imports = [ ./shellinit.nix ./demo.nix ];
    boot.loader.systemd-boot.enable = true;
    boot.loader.efi.canTouchEfiVariables = true;
    environment.shellInit = ''export MYVAR="default"'';
  }

.. code-block:: nix

  # shellinit.nix
  { config, lib, pkgs, ... }:
  {
    environment.shellInit = ''export MYVAR="from shellinit.nix"'';
  }

When we fire up our system, we will find that nothing conflicted, even though
the two files have differing values for ``environment.shellInit``.  Why not?

NixOS concatenated the two values together, joined by carriage returns, then it
has added the concatenated result to the shell init, which is injected into
``/etc/profile``.

When we fire up the system, we'll see that the MYVAR environment variable is
set to ``default``.  This is because ``/etc/profile`` has this in it:

.. code-block:: bash
                
  export MYVAR="from shellinit.nix"
  export MYVAR="default"

It added both lines to the file, but in an order such that the value in
``configuration.nix`` "won".

We can influence this using ``lib.mkAfter``:

.. code-block:: nix

  # configuration.nix
  { config, lib, pkgs, ... }:
  {
    imports = [ ./shellinit.nix ./demo.nix ];
    boot.loader.systemd-boot.enable = true;
    boot.loader.efi.canTouchEfiVariables = true;
    environment.shellInit = ''export MYVAR="default"'';
  }

.. code-block:: nix

  # shellinit.nix
  { config, lib, pkgs, ... }:
  {
    environment.shellInit = lib.mkAfter ''export MYVAR="from shellinit.nix"'';
  }

With the ``lib.mkAfter`` in place, when we fire up the system, we will see that
the ``/etc/profile`` now has this in it:

.. code-block:: bash
                
  export MYVAR="default"
  export MYVAR="from shellinit.nix"

And at runtime, $MYVAR is now "from shellinix.nix" as a result.

Although we are dealing with strings in our config, under the hood,
``environment.shellInit`` is a list and we are just influencing the list
ordering via a precedence via ``mkAfter``.  The list is joined with carriage
returns in order to compose the final string that is injected into
``/etc/profile``.

``lib.mkBefore`` is the inverse of ``lib.mkAfter``.

The "after" and "before" in ``lib.mkAfter`` and ``lib.mkBefore`` are
"before/after the default order".  Two values with the same precedence will be
ordered in the list in a more or less random way, or at least random to anyone
who isn't intimately familiar with Nix module system (which I am not).

``lib.mkOrder`` is a function that ``lib.mkBefore`` and ``lib.mkAfter`` are
based on that accepts an integer singifiying a precedence as well as the value.
