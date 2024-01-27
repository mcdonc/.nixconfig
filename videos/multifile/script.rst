=============================
 NixOS 70: Files as Functions
=============================

- Companion to video at https://youtu.be/CKHTLuijoqA

- This text script available via link in the video description.

- See the other videos in this series by visiting the playlist at
  https://www.youtube.com/playlist?list=PLa01scHy0YEmg8trm421aYq4OtPD8u1SN

Overview
========

This is independent of flakes or nonflakes.

Unlike many other languages, functions in Nix can be themselves composed as a
file.  This doesn't mean that the file *contains* a function, it means that the
file *is* a function.

As a demonstration (before we split things across files), let's assume we have
this stuff in our NixOS ``configuration.nix`` or some variant thereof.  We want
to create a derivation using ``pkgs.writeTextFile`` and then we put its
location in an environment variable.

.. code-block:: nix

    {pkgs, ...}:

    let

      myfile = pkgs.writeTextFile {
        name = "myfile";
        text = ''
           This is my file.
        '';
      };

    in

      environment.sessionVariables = {
        MYFILE = myfile;
      };


``myfile = pkgs.writeTextFile { ...`` is something that will create a
derivation in the Nix store (``writeTextFile`` is a wrapper around
``mkDerivation``) once it's realized.

Gratuitous aside: in the above example, the thing that causes ``myfile`` to
evaluate to anything at all is ``MYFILE = myfile;``.  If that stuff weren't
there, the file is not created.  This is the "lazy" bit of Nix.

After a ``nixos-rebuild switch`` and a relogin, we can see this crap had an
effect:

.. code-block:: bash

   $ env|grep MYFILE
   MYFILE=/nix/store/mvf00railwq15w8v42d9mz2kvqi36a08-myfile

The utility of such a thing is questionable, if I weren't trying to show you
how to convert this code into a file-as-a-function.  So let's take that example
and compose the thing that creates the derivation into a separate file.  Create
a file named ``myfile.nix`` right next to our ``configuration.nix``:

.. code-block:: nix

    {pkgs, ...}:

    # this is myfile.nix

    let

      myfile = pkgs.writeTextFile {
        name = "myfile";
        text = ''
           This is my file.
        '';
      };

    in
      myfile

Then within your ``configuration.nix``:

.. code-block:: nix

    {pkgs, ...}:

    let

      myfile = pkgs.callPackage ./myfile.nix {};
                
    in

      environment.sessionVariables = {
        MYFILE = myfile;
      };
  
Note this in ``myfile.nix``:

.. code-block:: nix

   in
     myfile

The last expression evaluated will be the return value of the function-file.
In our case, we return ``myfile``, which is an evaluated derivation.  This
becomes ``myfile`` in ``configuration.nix``, which we use just like we did in
the non-multifile example.

We used ``pkgs.callPackage`` with two arguments: a *path* to our ``myfile.nix``
and and attribute set (which is empty).  ``pkgs.callPackages`` is a magical
function that will pass along everything that was passed into
``configuration.nix`` to the downstream file.  You can also use the ``import``
function instead, which does the same thing without the magic.

Package?  Module?  Nix file?  Who fucking knows?

You may think that this idiom is somehow special and those latter curly braces
mean "the stuff that's in here" or something:

.. code-block:: nix

    {pkgs, ...}:

    {

       environment.systemPackages = [ curl ];

    }

But nope.  Any Nix file can be treated as a function.  The curly braces around
the ``environment.systemPackages`` just means the return value is an "attribtue
set" (aka a dictionary).  NixOS calls your ``configuration.nix`` and it's
expected to "return" an attribute set.  It needn't be, as we saw in the earlier
example.


