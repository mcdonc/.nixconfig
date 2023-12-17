==============================================================
NixOS 61: Using non-Nix Python Packages with Binaries on NixOS
==============================================================

- Companion to video at https://www.youtube.com/watch?v=7lVP4NJWJ9g

- This text script available via link in the video description.

- See the other videos in this series by visiting the playlist at
  https://www.youtube.com/playlist?list=PLa01scHy0YEmg8trm421aYq4OtPD8u1SN

Script
======

We'd like to do some data science work using NumPy and we just started using
NixOS.  It's just Linux right?!  Should work fine.

.. code:: shell

   $ cd ~/tmp
   $ python3.11 -m venv npenv
   $ npenv/bin/pip install numpy

.. code::

   Collecting numpy
     Obtaining dependency information for numpy from https://files.pythonhosted.org/packages/b6/ab/5b893944b1602a366893559bfb227fdfb3ad7c7629b2a80d039bb5924367/numpy-1.26.2-cp311-cp311-manylinux_2_17_x86_64.manylinux2014_x86_64.whl.metadata
     Using cached numpy-1.26.2-cp311-cp311-manylinux_2_17_x86_64.manylinux2014_x86_64.whl.metadata (61 kB)
   Using cached numpy-1.26.2-cp311-cp311-manylinux_2_17_x86_64.manylinux2014_x86_64.whl (18.2 MB)
   Installing collected packages: numpy
   Successfully installed numpy-1.26.2
   
Note that it installed a "manylinux" wheel for us.  Wheels are distribution
units that can contain binaries.  As the name implies, the NumPy wheel works on
many Linux distributions.
   
But when we try to use the NumPy we just installed on NixOS, we'll get an
error.

.. code:: shell

  $ npenv/bin/python -c "import numpy"

.. code::
   
  Traceback (most recent call last):
    File "/home/chrism/tmp/npenv/lib/python3.11/site-packages/numpy/core/__init__.py", line 24, in <module>
      from . import multiarray
    File "/home/chrism/tmp/npenv/lib/python3.11/site-packages/numpy/core/multiarray.py", line 10, in <module>
      from . import overrides
    File "/home/chrism/tmp/npenv/lib/python3.11/site-packages/numpy/core/overrides.py", line 8, in <module>
      from numpy.core._multiarray_umath import (
  ImportError: libz.so.1: cannot open shared object file: No such file or directory

  During handling of the above exception, another exception occurred:

  Traceback (most recent call last):
    File "/home/chrism/tmp/npenv/lib/python3.11/site-packages/numpy/__init__.py", line 130, in <module>
      from numpy.__config__ import show as show_config
    File "/home/chrism/tmp/npenv/lib/python3.11/site-packages/numpy/__config__.py", line 4, in <module>
      from numpy.core._multiarray_umath import (
    File "/home/chrism/tmp/npenv/lib/python3.11/site-packages/numpy/core/__init__.py", line 50, in <module>
      raise ImportError(msg)
  ImportError: 

  IMPORTANT: PLEASE READ THIS FOR ADVICE ON HOW TO SOLVE THIS ISSUE!

  Importing the numpy C-extensions failed. This error can happen for
  many reasons, often due to issues with your setup or how NumPy was
  installed.

  We have compiled some common reasons and troubleshooting tips at:

      https://numpy.org/devdocs/user/troubleshooting-importerror.html

  Please note and check the following:

    * The Python version is: Python3.11 from "/home/chrism/tmp/npenv/bin/python"
    * The NumPy version is: "1.26.2"

  and make sure that they are the versions you expect.
  Please carefully study the documentation linked above for further help.

  Original error was: libz.so.1: cannot open shared object file: No such file or directory


  The above exception was the direct cause of the following exception:

  Traceback (most recent call last):
    File "<string>", line 1, in <module>
    File "/home/chrism/tmp/npenv/lib/python3.11/site-packages/numpy/__init__.py", line 135, in <module>
      raise ImportError(msg) from e
  ImportError: Error importing numpy: you should not try to import numpy from
          its source directory; please exit the numpy source tree, and relaunch
          your python interpreter from there.

Wtf?  It worked ok on Ubuntu!

When the maintainers of NumPy created a wheel for distribution, the compiled
version of at least one of the binaries that ships in the distribution expects
the ``libz.so.1`` shared library file to be resolved by the link-loader, or for
it to be explicitly on the system library path (``LD_LIBRARY_PATH``).  On most
distributions, it will be found due to the nature of how their filesystems are
laid out.

But sometimes it won't.  The NumPy website has `exhaustive instructions
<https://numpy.org/doc/stable/user/troubleshooting-importerror.html>`_ about
debugging such a failure.  They even suggest disusing pip in favor of conda or
poetry because of such errors.

On a "normal" Linux distribution like Ubuntu, the failure could still happen.
The amelioration would be to do ``apt install zlib``.  Once this is done, the
``libz.so.1`` file will indeed be present in a filesystem location that is
checked by the .so-loader or present on ``LD_LIBRARY_PATH``.  And thus, NumPy
will begin to work.

As a first step, we need to do the same thing, or at least figure out which
NixOS package provides ``libz.so.1``.  To this end, we can add ``nix-index`` to
out configuration and rebuild:

.. code:: nix

   environment.systemPackages = with pkgs; [ nix-index ];

Now the ``nix-locate`` command will be available, so we can figure out which
Nix package provides the file::

  $ nix-index # (will take a few minutes)
  $ nix-locate --top-level libz.so.1
  zlib.out                                              0 s /nix/store/69jpyha5zbll6ppqzhbihhp51lac1hrp-zlib-1.2.13/lib/libz.so.1
  ...

It's in ``zlib.out``, which means the "out" output of the zlib package.

Search for ``zlib`` on https://search.nixos.org to see.

Let's add that package to our environment.systemPackages and rebuild.

.. code:: nix
   
   environment.systemPackages = with pkgs; [ nix-index zlib ];

Surely it will work now!

Nope!  Same error.  Why?

.. code::

   $ find npenv/lib/python3.11/site-packages/numpy -name "*.so"|xargs ldd|grep "not found"
	libz.so.1 => not found
	libz.so.1 => not found
	libz.so.1 => not found
        
NixOS is special.  It is not a FHS-compliant Linux distribution, so even though
we installed ``zlib``, the shared library binary in the NumPy wheel still can't
find ``libz.so.1`` because neither the link-loader can find it nor is it on the
system library path.

Now, it's tempting at this point to "just use Nix for everything."  Nix, of
course, has its own packaging of NumPy that works perfectly.  But in the real
world this is not always an option.  Organizations have build systems that
don't involve Nix, and, although *we* use Nix, not everyone does nor will the
suggestion always be appreciated by your boss.  Remember also that for the
purposes of this video, we are pretending we are new to Nix.  Suggesting
someone "learn Nix" to get this task done is often absurd.

`nix-ld <https://github.com/Mic92/nix-ld>`_ to the rescue!  ``nix-ld`` is a
package by Mic92.  It implements a stub dynamic loader in a FHS-compliant place
and creates a place on the file system that can act as a collection of
libraries that can be statically put on the library path that such that we can
use binaries that aren't packaged for Nix

To use it, enable ``nix-ld`` in your Nix configuration and rebuild:

.. code:: nix

  # enable nix-ld for pip and friends
  programs.nix-ld.enable = true;
  programs.nix-ld.libraries = with pkgs; [
    stdenv.cc.cc.lib
    zlib # numpy
  ];

(note that we no longer need ``zlib`` in our environment.systemPackages once
we do this).

Here's the link-loader it puts in an FHS-compliant place:

.. code:: shell

   $ ls /lib64/ld-linux-x86-64.so.2

This stub loader the real Nix link-loader after setting a composed
``LD_LIBRARY_PATH``, such that binaries not packaged for Nix that are executed
directly begin to work.

``nix-ld`` also allows you to add libraries to ``programs.nix-ld.libraries``
whose libraries are *also* placed in a place which becomes ``LD_LIBRARY_PATH``
(``/run/current-system/sw/share/nix-ld/lib``) when these things run.

.. code:: shell

    $ env|grep NIX_LD
    NIX_LD_LIBRARY_PATH=/run/current-system/sw/share/nix-ld/lib
    NIX_LD=/run/current-system/sw/share/nix-ld/lib/ld.so

    $ ls /run/current-system/sw/share/nix-ld/lib
    ld.so               libitm.so.1           libstdc++.so
    libasan.la          libitm.so.1.0.0       libstdc++.so.6
    libasan.so          liblsan.la            libstdc++.so.6.0.30
    libasan.so.8        liblsan.so            libstdc++.so.6.0.30-gdb.py
    libasan.so.8.0.0    liblsan.so.0          libsupc++.la
    libatomic.la        liblsan.so.0.0.0      libtsan.la
    libatomic.so        libquadmath.la        libtsan.so
    libatomic.so.1      libquadmath.so        libtsan.so.2
    libatomic.so.1.2.0  libquadmath.so.0      libtsan.so.2.0.0
    libgcc_s.so         libquadmath.so.0.0.0  libubsan.la
    libgcc_s.so.1       libssp.la             libubsan.so
    libgomp.la          libssp_nonshared.la   libubsan.so.1
    libgomp.so          libssp.so             libubsan.so.1.0.0
    libgomp.so.1        libssp.so.0           libz.so
    libgomp.so.1.0.0    libssp.so.0.0.0       libz.so.1
    libitm.la           libstdc++fs.la        libz.so.1.3
    libitm.so           libstdc++.la

So now that we've configured ``nix-ld``, surely things will work right?!

Nope.  Same error.

We need to do one more thing.  We need to set the ``LD_LIBRARY_PATH``
environment variable to the value of the ``NIX_LD_LIBRARY_PATH`` environment
variable.  The stub link-loader implemented by ``nix-ld`` is not interrogated by
NumPy (it is most often only interrogated by programs being run directly, not
by shared libraries, I think, I'm a little fuzzy here).  We need to tell it
statically where it can find the libraries it needs.

.. code:: shell
  
   $ export LD_LIBRARY_PATH=$NIX_LD_LIBRARY_PATH

See also `Mic92's explanation
<https://github.com/Mic92/nix-ld#my-pythonnodejsrubyinterpreter-libraries-do-not-find-the-libraries-configured-by-nix-ld>`_.

Now, finally things work:

.. code:: shell

   $ npenv/bin/python -c "import numpy"   

It's maybe best practice to do all this work in a ``nix-shell`` environment
rather than globally because setting ``LD_LIBRARY_PATH`` like that under NixOS
globally could cause other Nix programs to malfunction.  That said, most other
Linux platforms play fast and loose with shared library resolution, so if you
put the setting of ``LD_LIBRARY_PATH`` in your ``.bash_profile``, the worst
that can happen things might start going pear-shaped in exactly the same sort
of DLL-hell that is de rigeur on other Linux systems.

Here's a ``shell.nix`` nix-shell example we can put in ``/tmp`` that would
allow someone to successfully run ``npenv/bin/python -c "import numpy"`` after
installing numpy via pip and then running ``nix-shell``.  Note that this
requires at least ``programs.nix-ld.enable = true;`` somewhere in your Nix
config to work (but does not require any setting of
``programs.nix-ld.libraries`` nor any global setting of ``LD_LIBRARY_PATH``).

.. code:: nix

   with import <nixpkgs> {};

   mkShell {
     NIX_LD_LIBRARY_PATH = lib.makeLibraryPath [
       stdenv.cc.cc
       zlib
     ];
     NIX_LD = lib.fileContents "${stdenv.cc}/nix-support/dynamic-linker";
     buildInputs = [ python311 ];
     shellHook = ''
       export LD_LIBRARY_PATH=$NIX_LD_LIBRARY_PATH
     '';
   }

Alternatives
============

There is another way to do something similar using ``pkgs.buildFHSEnv`` and
``nix-shell``.  This is a nix file that runs the "tox" command against a
checked-out after setting up a FHS-compliant sandbox with some library
dependencies that I've scraped from a customer project.  If it was called
``tox.nix``, you'd run it via ``nix-shell tox.nix``.

.. code:: nix

   { pkgs ? import <nixpkgs> {} }:

   (pkgs.buildFHSEnv {
     name = "eao_dash-runtox";
     multiPkgs = pkgs: (with pkgs; [
       unixODBC
       imagemagick
       gcc
       (python311.withPackages (p: with p; [
         python311Packages.tox
       ]))
     ]);
     runScript = "tox";
   }).env

   
