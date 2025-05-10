NixOS 99: Post-Basic NixOS Config as a Mere Mortal
==================================================

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

This might be confusing if you're a programmer coming from a dynamic scripting
language like Python, where code in a separate file usually executes in its own
namespace when "imported".

When a Nix file is imported by NixOS, it's not like a Python import, where the
definitions of functions and classes in the imported code execute as the result
of the import, but thereafter those functions and classes lay around waiting to
be used in a second step.

Instead, the result of the import is to merge the NixOS configuration returned
by the imported file into the single NixOS configuration namespace.  In this
way, a Nix import is more like a C ``#include`` than it is like a Python
``import``.  Unlike a C ``#include``, it's not just a literal textual include,
it does dynamic execution during the import.  But like a C ``#include``, the
purpose is to pull more code into a global namespace.

There is magic happening under the hood of ``imports = []`` here, but as long
as you feed it files that have the same structure as ``configuration.nix``, you
can largely get by ignoring it.

By the way, to NixOS, the above configuration with the import of ``users.nix``
and the above configuration without the import are *equivalent*.  NixOS doesn't
care.  The resulting global namespace is the same when they are merged in
almost every meaningful way.  So you can use as many or as few files as you
like to compose your configuration, in any organization that fits your brain.

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

FYI, Nix experts tend to not call these "assignments", but instead "bindings."
There are good technical reasons for this.  Nonetheless, I'll stick with
"assignment" here.  It's close enough for our purposes.

Confusion about when and when not to use a semicolon is made a little worse by
Nix syntax, and its use of squiggly braces to mean multiple things, and
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
``{config, lib, pkgs, ... }:;`` or ``{config, lib, pkgs, ... };:``.

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
    } # there is a semicolon missing here
  }

These differences are hard to distinguish by a human deep in the weeds.  So it
is almost mandatory to use a code editor that points out syntax errors
interactively when you are editing Nix code.

``vim`` kinda helps with this via colorization, but without extensions, it
won't detect and point out when you've forgotten a semicolon or have too many
squiggly braces and so forth, except through that colorization.  I'm sure there
are extensions to vim which point out specific syntax errors in Nix code, and I
encourage you to track them down if you're a user.

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
the configuration attribute set.  In fact, a ``let .. in`` block is the *only*
place you can define arbitrary variables to be used elsewhere in the same
configuration file.

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
and ``environment.systemPackages``, etc), you are filling in predefined slots
offered up by NixOS configuration options.

``boot.loader.systemd-boot.enable``, ``boot.loader.efi.canTouchEfiVariables``,
and ``users.users.<name>`` are some of those slots.  They are defined within
NixOS "options" in Nixpkgs, and options have a schema. NixOS checks what you
provide against them when you run ``nixos-rebuild``.  First NixOS composes the
big global attribute set representing the values you've given for specific
options, then it checks those values against the option schemas when you run
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
configuration options in the file they're being imported into. But NixOS will
often be able to deconflict them.

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

Of note: we have two conflicting definitions of ``environment.systemPackages``,
one in each file.

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

And sure enough, ``nixos-rebuild switch`` will complain bitterly about these
two definitions for ``networking.networkmanager.enable`` conflicting.

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

For example, let's try to set two differing string values for the NixOS
configuration option named ``environment.shellInit`` (an option that adds lines
to ``/etc/profile``) within two files:

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

When we run ``nixos-rebuild``, we will find that nothing conflicted, even
though the two files have differing values for ``environment.shellInit``.  Why
not?

NixOS concatenated the two values together, joined by linefeed characters, then
it injected the concatenated result into ``/etc/profile``.

When we log in to the system system, we'll see that the ``echo $MYVAR`` returns
``default``.  This is because ``/etc/profile`` has this in it:

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

And at runtime, ``$MYVAR`` is now ``from shellinit.nix`` as a result.

Although we are dealing with simple strings in our config, under the hood,
``environment.shellInit`` is a Nix ``lines`` option.  When you provide a
``lines`` option one or more values, NixOS collects the raw text you've
provided to it from your various imports into an unordered list.  Then it
orders the list.  After the list is ordered, its values are joined together
with linefeeds to compose the final block of text that is injected into
``/etc/profile``.

In our case, we are influencing the list ordering via a precedence via
``mkAfter`` before Nix injects it into ``/etc/profile``.  By using ``mkAfter``,
we are telling Nix to sort our ``export MYVAR="from shellinix.nix"`` value to
the bottom.

``lib.mkBefore`` is obviously the inverse of ``lib.mkAfter``.

The "after" and "before" in ``lib.mkAfter`` and ``lib.mkBefore`` are
"before/after the default order".  Two values with the same precedence will be
ordered in the list in a more or less abtitrary way, or at least arbitrary to
anyone who isn't intimately familiar with the Nix module system (which I am
not).  FYI, "module system" is what Nix folks call the set of code and
conventions that does all this merging and deconflicting and schema-checking
and whatnot.

``lib.mkOrder`` is a function that ``lib.mkBefore`` and ``lib.mkAfter`` are
based on that accepts an integer singifiying a precedence as well as the value.

In the wild, ``lib.mkBefore`` and ``lib.mkAfter`` are not used as frequently as
``lib.mkDefault`` or ``lib.mkForce`` because they are useful and appropriate in
a more limited set of circumstances.

Tracebacks
----------

When you introduce a syntax error or assign the wrong type to a configuration
option, or make any other manner of mistake that humans make when you change
your configuration, you'll get a traceback when you run ``nixos-rebuild``.

For example, let's inject a syntax error into a ``configuration.nix`` file:

.. code-block:: nix

  # configuration.nix
  { config, lib, pkgs, ... }:
  {
    imports = [ ./demo.nix ];
    boot.loader.systemd-boot.enable = true;
    boot.loader.efi.canTouchEfiVariables = true;
    networking.networkmanager.enable = true;
    environment.systemPackages = with pkgs; [ vim ];
  }

Let's add a semicolon to the ending squiggly brace to introduce the syntax
error:

.. code-block:: nix

  # configuration.nix
  { config, lib, pkgs, ... }:
  {
    imports = [ ./demo.nix ];
    boot.loader.systemd-boot.enable = true;
    boot.loader.efi.canTouchEfiVariables = true;
    networking.networkmanager.enable = true;
    environment.systemPackages = with pkgs; [ vim ];
  }; # this semicolon doesn't belong here

When we run ``nixos-rebuild switch``, we'll be provided a traceback, which has
at its end::

  error: syntax error, unexpected ';', expecting end of file
  at /nix/store/5lld1qw2m272giszwpx588fn0ml03jdw-source/videos/composition/nixos/configuration.nix:8:2:
    7|   environment.shellInit = ''export MYVAR="default"'';
    8| };
     |  ^
    9|

Some traceback error messages are pretty easy to interpret.  This is one of
them.  It's hinting "please remove this semicolon on this line in this file".

For another common demonstration of a useful traceback provided by NixOS,
let's use this configuration:

.. code-block:: nix

  # configuration.nix
  { config, lib, pkgs, ... }:
  {
    imports = [ ./demo.nix ];
    boot.loader.systemd-boot.enable = true;
    boot.loader.efi.canTouchEfiVariables = "a"; # supposed to be a boolean
    networking.networkmanager.enable = true;
    environment.systemPackages = with pkgs; [ vim ];
  }

When we run ``nixos-rebuild``, we'll see a traceback that ends with something
like::
       error: A definition for option `virtualisation.vmVariant.boot.loader.efi.canTouchEfiVariables' is not of type `boolean'. Definition values:
       - In `/nix/store/ryka46rd7shpihpla0m8ibgl9i4n7i6q-source/videos/composition/nixos/configuration.nix': "a string"
  
It's letting you know that you gave ``boot.loader.efi.canTouchEfiVariables``
(please ignore the ``virtualization.vmVariant`` prefix, that's a product of my
demo environment) the wrong kind of value; it's a string when it should be a
boolean.  It tells you the filename in which the offense has taken place.

We can see that if you stick to the basics, Nix tracebacks generally do a
pretty good job of telling you what and where the problem is.

But when you start wading into Nix beyond the basics, commonly, you will be
presented with tracebacks from Nix during your change/test loop that initially
seem to have absolutely nothing whatsoever to do with any changes you made.  Or
the information in the traceback is too terse.

As an example, let's use this ``configuration.nix``:

.. code-block:: nix

    # configuration.nix
    { config, lib, pkgs, ... }:
    let
      zshi = pkgs.stdenv.mkDerivation {
        name="devenv-zsh-zshi";
        src = pkgs.fetchFromGitHub {
          owner = "romkatv";
          repo = "zshi";
          rev = "c9c90687448a1f0aae30d9474026de608dc90734";
          sha256 = "sha256-OB96i93ZxKDgOqIFq1jM9l+wxAisRXtSCBcHbYDvxsI=";
        };
        installPhase = ''
          mkdir -p $out/bin
          cp zshi $out/bin/zshi
          substituteInPlace $out/bin/zshi \
            --replace '/usr/bin/env zsh' ${pkgs.zsh}/bin/zsh \
            --replace 'ZDOTDIR=$tmp zsh' 'ZDOTDIR=$tmp ${pkgs.zsh}/bin/zsh'
         ${1/2}
        '';
        meta = with lib; {
          description = "ZSH -i but initial command exec'd after std zsh files";
          homepage = "https://github.com/romkatv/zshi";
          license = licenses.mit;
          platforms = platforms.all;
        };
      };
    in
    {
      imports = [ ./demo.nix ];
      boot.loader.systemd-boot.enable = true;
      boot.loader.efi.canTouchEfiVariables = true;
      environment.systemPackages = [ zshi ];
    }

This is more complex than any other ``configuration.nix`` we've seen so far
because it packages up Roman Perepelitsa's zshi
(https://github.com/romkatv/zshi), which is a handy tool that helps you run
some abitrary configuration before invoking the zsh shell.

When we run ``nixos-rebuild``, here is the last few lines of the traceback we
get::

    (stack trace truncated; use '--show-trace' to show the full, detailed trace)

    error: path '/nix/store/wi1m6b9j0jir84kxwfb1c091kx44g9vf-source/videos/composition/nixos/1/2' does not exist

What the heck is that supposed to mean?  Well, mot much to us, really.  It
suggests running ``nixos-rebuild`` with the ```--show-trace`` flag, so let's do
that::

        … while calling the 'derivationStrict' builtin
         at <nix/derivation-internal.nix>:37:12:
           36|
           37|   strict = derivationStrict drvAttrs;
             |            ^
           38|

       … while evaluating derivation 'devenv-zsh-zshi'
         whose name attribute is located at /nix/store/yhc8a0a2mvbp8fp53l57i3d5cnz735fc-source/pkgs/stdenv/generic/make-derivation.nix:439:13

       … while evaluating attribute 'installPhase' of derivation 'devenv-zsh-zshi'
         at /nix/store/ixsbka0wp7vxd5fz8a1dqbdpr7ywgq90-source/videos/composition/nixos/configuration.nix:12:5:
           11|     };
           12|     installPhase = ''
             |     ^
           13|       mkdir -p $out/bin

       error: path '/nix/store/ixsbka0wp7vxd5fz8a1dqbdpr7ywgq90-source/videos/composition/nixos/1/2' does not exist

That's a little better.  it's telling us there is a problem with the
``installPhase`` of our mkDerivation call.  And indeed as the last line of that
string there is a line that says ``${1/2}``.  We just pasted it in from
somewhere else mistakenly.  Removing it silences the traceback.

There are far more horrific traceback situations you can wind up in.  Often
invoking ``--show-trace`` is not helpful at all.  Sometimes there may be a bug
in a ``nixpkgs`` module that causes a mystifying error when you supply it a
value it doesn't expect.  Following a traceback "up the stack" is often not
viable because of the lazy evaluation features of Nix.  It's just too long of a
stack.

So things can get challenging.  These are some of the general reasons / excuses
for that:

- When you edit ``configuration.nix``, yhou are writing code, not merely
  editing a configuration file.

- You can't directly control the order in which Nix evaluates your code.

- Unlike other languages, Nix is lazily evaluated, which means that a value
  isn't evaluated until it is absolutely necessary.

- NixOS is a framework written mostly in Nix.

The order in which statements are defined in your configuration files is
largely meaningless at ``nix-rebuild`` time.  Nix doesn't descend your
``configuration.nix`` in some line-oriented way, evaluating the first
assignment, then the next, etc.  Your ``configuration.nix`` really isn't a
configuration file.  It's code.

Nix collects the values you provide via that code into an attribute set that
may come from many different files, and then operates against that.

The code that operates against your configuration values lives in ``nixpkgs``.
That code won't evaluate your configuration values in the order they are
presented in ``configuration.nix`` at all.  It instead evaluates your code in
an order that you cannot completely control.

When things are evaluated in an order you don't understand, the tracebacks you
receive when you make a mistake may be mystifying.

Nix is also lazy.  Nix, in fact, is *so damn lazy* that if you invoke
``nixos-rebuild`` and then switch back to editing your Nix code, the changes
you're in the process of making in your editor will influence the
``nixos-rebuild`` run you just kicked off if you save those changes quickly
enough.  It's that lazy.

This presents a different kind of ordering issue.  Because statements are not
evaluated eagerly, they might not be evaluated until very late in the rebuild
process instead of when you might think they were, or should have been.  This
can also result in impenetrable tracebacks.

Meanwhile, what is evaluating your ``configuration.nix`` code?  Other Nix code
that you didn't write.  And *all* the Nix code involved in reifying your
configuration will show up in the traceback.  Nix is a framework.

These features of Nix, combined, will eventually, invariably, wind you up in a
place where you get tracebacks that are less understandable than the ones we've
seen so far.  I'd suggest asking for help liberally on the NixOS Discourse when
this happens.

