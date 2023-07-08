NixOS 45: Dynamic Library Linking Under NixOS: How Do It Work?
==============================================================

- Companion to video at 

- See the other videos in this series by visiting the playlist at
  https://www.youtube.com/playlist?list=PLa01scHy0YEmg8trm421aYq4OtPD8u1SN

Video Script
------------

Overview
========

- What we are about to discuss solves a whole category of problems that are
  collectively known as "DLL hell".  DLL hell exists because only one canonical
  copy of a shared library is typically imagined to exist on a host at any
  given time.  However, contracts between software change, and a newer version
  of a shared library may not be compatible with older executables.  Or an
  older library may not be compatible with newer executables.

- Nix gives us some savlation from DLL hell.  This salvation is why you can
  install Nix on most any Linux or MacOS platform and install some majority of
  the 80,000 packages in the nixpkgs repository, and have confidence that they
  will work and won't be broken incidentally by anything you do to the host
  system or by other packages you add to the Nix system.

- It's why you can often install eight-year-old Nix software on a distribution
  that is one month old.  It's why you can often install one-month-old Nix
  software on a distribution that is eight years old.  At least if ABI
  compatibility is maintained across time in these distributions, which, on
  Linux at least, is nominally guaranteed.  It's why Nix is a much better
  solution on MacOS than something like ``homebrew``, which finds itself unable
  to support older versions of MacOS over time.

- To these ends, Nix does awesome things to help you build software that you
  can install non-globally more easily.  "Non-globally" means that multiple
  versions of the software you're building can exist on the system
  simultaneously, and each version can have different build-time and runtime
  dependencies.

- This serves a similar purpose to systems such as the Linux ``snap`` and
  ``flatpak`` packaging standards.  Unlike systems such as ``snap`` and
  ``flatpak``, however, software you package can depend on other software you
  package separately.  It's not an all-or-nothing proposition.  There is no
  containerization involved in Nix packaging (unless you want it).  It's more
  granular than those systems, and does not rely on operating system
  namespacing.
  
- This comes at a cost. It is typically harder to build software for Nix than
  for other systems.  This is not really Nix's fault.  It's more the fault of
  60 years worth of assumptions about how software is typically built, most
  notably the assumption of singleton global locations for shared libraries and
  support files.  Building Nix packages is largely the task of detecting and
  fixing these assumptions in the software you're trying to package.  This can
  be very challenging.

Details
=======

- For the record, this is only about C/C++ dynamic libraries using the
  GNU toolchain.  I don't know beans about other languages/toolchains that
  support dynamic libraries.

- Going to assume you have some experience compiling C/C++ software from
  source on other platforms.

- The unit of software packaging in Nix is called a derivation.

- The Nix function most commonly used to create a derivation is called
  ``stdenv.mkDerivation``.

- ``stdenv.mkDerivation`` is a wrapper around a more basic
  ``builtins.derivation`` function defined in NixOS.  Unlike
  ``builtins.derivation``, ``stdenv.mkDerivation`` supplies default build
  inputs, a set of default build phases (defined in bash) that are sensible for
  an autotools project, and a set of default phase "hooks" that you can
  override to customize the build.  If you really want to dive in to how
  derivations work under the hood, you can see how the ``builtins.derivation``
  function works in a series of excellent articles by Luca Bruno, starting at
  https://lethalman.blogspot.com/2014/07/nix-pill-6-our-first-derivation.html.
  I'm going to stick with describing things in terms of
  ``stdenv.mkDerivation`` here.

- ``stdenv.mkDerivation`` in it most simple form has some implicit package
  dependencies.  These are, by default, useful for autotools
  (configure-then-make-based) projects.  From a quick reading of
  https://github.com/NixOS/nixpkgs/blob/master/pkgs/stdenv/linux/default.nix ,
  on Linux, at least, they they appear to be ``bintools``, ``binutils``,
  ``libc``, ``gcc``, ``coreutils``, ``bash``, ``gnumake``, ``bzip2``, ``xz``,
  ``diffutils``, ``findutils``, ``gawk``, ``gmp``, ``gnused``, ``gnutar``,
  ``gnugrep``, ``gnupatch``, ``patchelf``, ``ed``, ``file``, ``attr``, ``acl``,
  ``zlib``, ``pcre``, ``libidn2``, ``libunistring`` and maybe some other
  packages that are required by GNU autotools that I may have missed due to
  abstractions in that code.  When you run ``stdenv.mkDerivation``, if these
  are not already installed (highly unlikely), Nix will install them for you.
  This set of packages can be thought of sort of like the ``build-essential``
  metapackage on Debian/Ubuntu.
  
- When you build a Nix derivation, it will depend on exactly the versions of
  the "build inputs" you provide.  Nix derivations name their build inputs
  via arguments to ``stdenv.mkDerivation`` named ``buildInputs``,
  ``propagatedBuildInputs`` and ``nativeBuildInputs``.  Derivations in
  nixpkgs are typicaly tightly-specified -- they will typically contain some
  unchanging version of the software being built, like a tarball or a git
  tag.  Because build inputs are also derivations, they share the same
  quality.
  
- "But we only named build dependencies, we didn't name runtime
  dependencies," you say.  True!  There is deep magic here.  Under Nix, we
  conflate build-time dependencies with the runtime dependencies and let Nix
  sort out the differences out for us.  Some (but not all) of the build
  inputs will become runtime dependencies.  For example, some version of
  ``gcc`` is always a build input for C/C++ projects (although most often
  implicitly as described above), but it will rarely become a runtime
  dependency.

- To detect actual runtime dependencies, after the software is built, Nix
  scans all the files in the binary output(s) of a derivation to determine
  which packages in your build inputs are needed at runtime.  It literally
  just kinda binary-greps each file in your derivation's output for
  ``/nix/store`` plus each build input's *hash*.  For example if
  ``curl-8.0.1`` is a build input and the derivation of the version of
  ``curl`` you're depending on has a hash of
  ``03j8nhpi7vj9xl2pxkrxkf62viwxsaz8``, if scanning sees the string
  ``/nix/store/03j8nhpi7vj9xl2pxkrxkf62viwxsaz8`` in any file in the output,
  it will consider ``/nix/store/03j8nhpi7vj9xl2pxkrxkf62viwxsaz8-curl-8.0.1``
  a runtime dependency (the ``curl-8.0.1`` bit is superfluous to dependency
  detection, useful only to humans).  If a build input's hash is found in any
  output, it is a runtime dependency.  If it's not, it isn't.
  
  More info:
  https://stackoverflow.com/questions/34769296/build-versus-runtime-dependencies-in-nix
  and https://lethalman.blogspot.com/2014/08/nix-pill-9-automatic-runtime.html

- Things that are in your derivation's build inputs whose /nix/store-hashes
  are anywhere in the output files will generally cause the directories that
  contain the inputs' dynamic library files (``.so`` files) to be added as
  RPATH entries to all binaries and shared library files
  (Executable-and-Linkable-Format aka "ELF" files) that exist within the
  output director(y|ies).  Usually this boils down to putting the "lib"
  directory of each detected input (which will be somewhere in a subdirectory
  of in ``/nix/store``) on the RPATH of each binary in the output.  RPATH is
  the runtime search path for the GNU loader
  (https://en.wikipedia.org/wiki/Rpath).

- This isn't quite true, because some of the detected "runtime dependencies"
  are unneccessary (e.g. sometimes the GCC linker is detected as a runtime
  dependency).  These are stripped out based on heuristics that I don't yet
  understand.  But this is known as "shrinking" the RPATH.

- Patchelf https://github.com/NixOS/patchelf is used to do both the initial
  RPATH writing and its shrinking.
  
- ``autoPatchelfHook``
  https://github.com/NixOS/nixpkgs/blob/master/pkgs/build-support/setup-hooks/auto-patchelf.sh
  is a thing we can put in our built inputs that will do all of this magically.
  If it is included as a build input, it will call ``patchelf`` at the end of
  the build process to do the RPATH writing and shrinking for us.

- Here's the simplest possible C++ program that uses a third-party external
  shared library.  It does nothing useful except include a shared library named
  ``boolector``::

    #include <iostream>
    #include "boolector.h"

    using namespace std;
    int main()
    {
        Btor* btor = boolector_new();
        cout << "hello from file that uses a shared library";
        boolector_delete(btor);
    }
  
- Here's a Makefile that you might imagine would build and install such a
  thing::

    ifeq ($(PREFIX),)
        PREFIX := /usr/local
    endif

    bool:
            g++ -lboolector -I/usr/local/include/boolector bool.cc -o bool

    install:
            install -d $(PREFIX)
            install -m 755 bool $(PREFIX)

    all: bool
    
- Imagine we've put these two files into a directory named bool and tgz'ed them
  up like::

    tar cvzf bool.tar.gz bool

- We now have a tar.gz that we can use as a derivation source input.

- Let's create a file that contains a simple nix expression that will build
  this as a derivation, called ``bool.nix``.  It will assume that the
  ``bool.tgz`` file lives alongside it in the same directory.  Since the
  ``Makefile`` of our ``bool`` project lets us override the install prefix, we
  do so with an environment variable setting in ``preBuild``::

    with import <nixpkgs> {};

    stdenv.mkDerivation {
      name = "bool";
      src = ./bool.tar.gz;
      preBuild = ''
        export PREFIX=$out
      '';
      buildInputs = [ boolector ];
    }
    
- We can use ``nix-build`` to realize the derivation::

    [nix-shell:/etc/nixos/videos/patchelf]$ nix-build bool.nix 
    this derivation will be built:
      /nix/store/5ghdrfn4l186rab8d1jrj22zjpd7wx3a-bool.drv
    building '/nix/store/5ghdrfn4l186rab8d1jrj22zjpd7wx3a-bool.drv'...
    unpacking sources
    unpacking source archive /nix/store/vm8c999xm21wg5g1whqk91d5prdaiihv-bool.tar.gz
    source root is bool
    setting SOURCE_DATE_EPOCH to timestamp 1688842207 of file bool/Makefile
    patching sources
    configuring
    no configure script, doing nothing
    building
    build flags: SHELL=/nix/store/7q1b1bsmxi91zci6g8714rcljl620y7f-bash-5.2-p15/bin/bash
    g++ -lboolector -I/usr/local/include/boolector bool.cc -o bool
    installing
    install flags: SHELL=/nix/store/7q1b1bsmxi91zci6g8714rcljl620y7f-bash-5.2-p15/bin/bash install
    install -d /nix/store/w5dm8xxgmj13cl5dkfc55pwws0ixkhym-bool
    install -m 755 bool /nix/store/w5dm8xxgmj13cl5dkfc55pwws0ixkhym-bool
    post-installation fixup
    shrinking RPATHs of ELF executables and libraries in /nix/store/w5dm8xxgmj13cl5dkfc55pwws0ixkhym-bool
    shrinking /nix/store/w5dm8xxgmj13cl5dkfc55pwws0ixkhym-bool/bool
    checking for references to /build/ in /nix/store/w5dm8xxgmj13cl5dkfc55pwws0ixkhym-bool...
    patching script interpreter paths in /nix/store/w5dm8xxgmj13cl5dkfc55pwws0ixkhym-bool
    /nix/store/w5dm8xxgmj13cl5dkfc55pwws0ixkhym-bool
    
- The first thing to note is that although the Makefile specified the boolector
  include file as ``-I/usr/local/include/boolector``, such a path doesn't exist
  on NixOS.  But, not to fear, Nix augments our include and library paths for
  us during the build, to include all of the include and library paths that are
  provided by our build inputs.  Since ``boolector`` is one of our build
  inputs, our ``boolector.h`` file is found.

- We can see this in action by using the ``NIX_DEBUG`` flag when we run
  ``nix-build``.  To do this, we can add a ``preBuild`` argument to our call to
  ``stdenv.mkDerivation`` within ``bool.nix``::

    with import <nixpkgs> {};

    stdenv.mkDerivation {
      name = "bool";
      src = ./bool.tar.gz;
      preBuild = ''
        export PREFIX=$out
        export NIX_DEBUG=1
      '';
      buildInputs = [ boolector ];
    }

- Once we've done that, if we rerun ``nix-build bool.nix``, we see something
  like this in its output::

    [chrism@thinknix512:/etc/nixos/videos/patchelf]$ nix-build bool.nix
    
    ... elided ...

    original flags to /nix/store/hqbh8ibqaq8x6riwz48xvyx4dvvldd9f-gcc-12.2.0/bin/g++:
      -lboolector
      bool.cc
      -o
      bool
    extra flags after to /nix/store/hqbh8ibqaq8x6riwz48xvyx4dvvldd9f-gcc-12.2.0/bin/g++:
      -B/nix/store/dg8mpqqykmw9c7l0bgzzb5znkymlbfjw-glibc-2.37-8/lib/
      -idirafter
      /nix/store/dpk5m64n0axk01fq8h2m0yl9hhpq2nqk-glibc-2.37-8-dev/include
      -idirafter
      /nix/store/hqbh8ibqaq8x6riwz48xvyx4dvvldd9f-gcc-12.2.0/lib/gcc/x86_64-unknown-linux-gnu/12.2.0/include-fixed
      -B/nix/store/sm14bmd3l61p5m0q7wa5g7rz2bl6azqf-gcc-12.2.0-lib/lib
      -B/nix/store/d9fndiing52fkalp5knfalrvlb3isi6w-gcc-wrapper-12.2.0/bin/
      -frandom-seed=8izj949rmz
      -isystem
      /nix/store/ms3p2368syy33q1ac4ln2mk823h3g0a0-boolector-3.2.2/include
      -isystem
      /nix/store/ms3p2368syy33q1ac4ln2mk823h3g0a0-boolector-3.2.2/include
      -Wl\,-rpath
      -Wl\,/nix/store/8izj949rmzylg2wl9kcglpk9rn21k06i-bool/lib64
      -Wl\,-rpath
      -Wl\,/nix/store/8izj949rmzylg2wl9kcglpk9rn21k06i-bool/lib
      -L/nix/store/ms3p2368syy33q1ac4ln2mk823h3g0a0-boolector-3.2.2/lib
      -L/nix/store/ms3p2368syy33q1ac4ln2mk823h3g0a0-boolector-3.2.2/lib
      -L/nix/store/dg8mpqqykmw9c7l0bgzzb5znkymlbfjw-glibc-2.37-8/lib
      -L/nix/store/hqbh8ibqaq8x6riwz48xvyx4dvvldd9f-gcc-12.2.0/lib/gcc/x86_64-unknown-linux-gnu/12.2.0
      -L/nix/store/sm14bmd3l61p5m0q7wa5g7rz2bl6azqf-gcc-12.2.0-lib/x86_64-unknown-linux-gnu/lib
      -L/nix/store/sm14bmd3l61p5m0q7wa5g7rz2bl6azqf-gcc-12.2.0-lib/lib

    ... elided ...
    
    extra flags before to /nix/store/dx8hynidprz3kf4ngcjipnwaxp6h229f-binutils-2.40/bin/ld:
      -z
      relro
      -z
      now
    original flags to /nix/store/dx8hynidprz3kf4ngcjipnwaxp6h229f-binutils-2.40/bin/ld:
      -plugin
      /nix/store/hqbh8ibqaq8x6riwz48xvyx4dvvldd9f-gcc-12.2.0/libexec/gcc/x86_64-unknown-linux-gnu/12.2.0/liblto_plugin.so
      -plugin-opt=/nix/store/hqbh8ibqaq8x6riwz48xvyx4dvvldd9f-gcc-12.2.0/libexec/gcc/x86_64-unknown-linux-gnu/12.2.0/lto-wrapper
      -plugin-opt=-fresolution=/build/ccgV4YHB.res
      -plugin-opt=-pass-through=-lgcc_s
      -plugin-opt=-pass-through=-lgcc
      -plugin-opt=-pass-through=-lc
      -plugin-opt=-pass-through=-lgcc_s
      -plugin-opt=-pass-through=-lgcc
      --eh-frame-hdr
      -m
      elf_x86_64
      -dynamic-linker
      /nix/store/dg8mpqqykmw9c7l0bgzzb5znkymlbfjw-glibc-2.37-8/lib64/ld-linux-x86-64.so.2
      -o
      bool
      /nix/store/dg8mpqqykmw9c7l0bgzzb5znkymlbfjw-glibc-2.37-8/lib/crt1.o
      /nix/store/dg8mpqqykmw9c7l0bgzzb5znkymlbfjw-glibc-2.37-8/lib/crti.o
      /nix/store/hqbh8ibqaq8x6riwz48xvyx4dvvldd9f-gcc-12.2.0/lib/gcc/x86_64-unknown-linux-gnu/12.2.0/crtbegin.o
      -L/nix/store/ms3p2368syy33q1ac4ln2mk823h3g0a0-boolector-3.2.2/lib
      -L/nix/store/ms3p2368syy33q1ac4ln2mk823h3g0a0-boolector-3.2.2/lib
      -L/nix/store/dg8mpqqykmw9c7l0bgzzb5znkymlbfjw-glibc-2.37-8/lib
      -L/nix/store/hqbh8ibqaq8x6riwz48xvyx4dvvldd9f-gcc-12.2.0/lib/gcc/x86_64-unknown-linux-gnu/12.2.0
      -L/nix/store/sm14bmd3l61p5m0q7wa5g7rz2bl6azqf-gcc-12.2.0-lib/x86_64-unknown-linux-gnu/lib
      -L/nix/store/sm14bmd3l61p5m0q7wa5g7rz2bl6azqf-gcc-12.2.0-lib/lib
      -L/nix/store/dg8mpqqykmw9c7l0bgzzb5znkymlbfjw-glibc-2.37-8/lib
      -L/nix/store/sm14bmd3l61p5m0q7wa5g7rz2bl6azqf-gcc-12.2.0-lib/lib
      -L/nix/store/d9fndiing52fkalp5knfalrvlb3isi6w-gcc-wrapper-12.2.0/bin
      -L/nix/store/hqbh8ibqaq8x6riwz48xvyx4dvvldd9f-gcc-12.2.0/lib/gcc/x86_64-unknown-linux-gnu/12.2.0
      -L/nix/store/hqbh8ibqaq8x6riwz48xvyx4dvvldd9f-gcc-12.2.0/lib/gcc/x86_64-unknown-linux-gnu/12.2.0/../../../../lib64
      -L/nix/store/hqbh8ibqaq8x6riwz48xvyx4dvvldd9f-gcc-12.2.0/lib/gcc/x86_64-unknown-linux-gnu/12.2.0/../../..
      -dynamic-linker=/nix/store/dg8mpqqykmw9c7l0bgzzb5znkymlbfjw-glibc-2.37-8/lib/ld-linux-x86-64.so.2
      -lboolector
      /build/cc6TFnuw.o
      -rpath
      /nix/store/8izj949rmzylg2wl9kcglpk9rn21k06i-bool/lib64
      -rpath
      /nix/store/8izj949rmzylg2wl9kcglpk9rn21k06i-bool/lib
      -lstdc++
      -lm
      -lgcc_s
      -lgcc
      -lc
      -lgcc_s
      -lgcc
      /nix/store/hqbh8ibqaq8x6riwz48xvyx4dvvldd9f-gcc-12.2.0/lib/gcc/x86_64-unknown-linux-gnu/12.2.0/crtend.o
      /nix/store/dg8mpqqykmw9c7l0bgzzb5znkymlbfjw-glibc-2.37-8/lib/crtn.o
    extra flags after to /nix/store/dx8hynidprz3kf4ngcjipnwaxp6h229f-binutils-2.40/bin/ld:
      -rpath
      /nix/store/ms3p2368syy33q1ac4ln2mk823h3g0a0-boolector-3.2.2/lib
      -rpath
      /nix/store/dg8mpqqykmw9c7l0bgzzb5znkymlbfjw-glibc-2.37-8/lib
      -rpath
      /nix/store/sm14bmd3l61p5m0q7wa5g7rz2bl6azqf-gcc-12.2.0-lib/lib

- This is a lot of gobbeldy-gook mostly but the important bits are the last few
  lines.  Nix, under the hood aguements any flags we've supplied to the GNU
  linker (``ld``).  In particular, one turns the reference to the ``boolector``
  library into an RPATH.  That means that our ``bool`` executable will now have
  an entry in its ELF metadata that means "when ``bool`` tries to use a
  function from any shared library, include this path on the search path for
  shared libraries."  This means that the ``bool`` executable is tied entirely
  to the /nix/store-version of ``boolector`` that was used when ``nix-build``
  was run.  Not any old generic version of ``boolector``.  This and only this
  version.
  
- We can see this by visiting the ``result`` symlink left by ``nix-build`` and
  using ``ldd`` to examine the paths it will search for shared libraries::

    [nix-shell:/etc/nixos/videos/patchelf]$ cd result
    [nix-shell:/etc/nixos/videos/patchelf/result]$ ldd bool 
        linux-vdso.so.1 (0x00007f8a026dc000)
        libboolector.so => /nix/store/ms3p2368syy33q1ac4ln2mk823h3g0a0-boolector-3.2.2/lib/libboolector.so (0x00007f8a0254f000)
        libstdc++.so.6 => /nix/store/sm14bmd3l61p5m0q7wa5g7rz2bl6azqf-gcc-12.2.0-lib/lib/libstdc++.so.6 (0x00007f8a02329000)
        libm.so.6 => /nix/store/dg8mpqqykmw9c7l0bgzzb5znkymlbfjw-glibc-2.37-8/lib/libm.so.6 (0x00007f8a02249000)
        libgcc_s.so.1 => /nix/store/sm14bmd3l61p5m0q7wa5g7rz2bl6azqf-gcc-12.2.0-lib/lib/libgcc_s.so.1 (0x00007f8a02228000)
        libc.so.6 => /nix/store/dg8mpqqykmw9c7l0bgzzb5znkymlbfjw-glibc-2.37-8/lib/libc.so.6 (0x00007f8a02042000)
        libbtor2parser.so => /nix/store/qnxzw6whxs8783c07m32ac0hdfrhmb8v-btor2tools-1.0.0-pre_9831f9909fb283752a3d6d60d43613173bd8af42-lib/lib/libbtor2parser.so (0x00007f8a02035000)
        libgmp.so.10 => /nix/store/0h2qlf5y50h7g3ir92pr91sjig6nhdhp-gmp-with-cxx-6.2.1/lib/libgmp.so.10 (0x00007f8a01f95000)
        /nix/store/dg8mpqqykmw9c7l0bgzzb5znkymlbfjw-glibc-2.37-8/lib/ld-linux-x86-64.so.2 => /nix/store/dg8mpqqykmw9c7l0bgzzb5znkymlbfjw-glibc-2.37-8/lib64/ld-linux-x86-64.so.2 (0x00007f8a026de000)

- Note that it also includes RPATHS, transitively, for dependencies of
  ``boolector``::

    [nix-shell:/etc/nixos/videos/patchelf/result]$ cd /nix/store/ms3p2368syy33q1ac4ln2mk823h3g0a0-boolector-3.2.2/lib
    [nix-shell:/nix/store/ms3p2368syy33q1ac4ln2mk823h3g0a0-boolector-3.2.2/lib]$ ldd libboolector.so 
            linux-vdso.so.1 (0x00007ffeebbc3000)
            libbtor2parser.so => /nix/store/qnxzw6whxs8783c07m32ac0hdfrhmb8v-btor2tools-1.0.0-pre_9831f9909fb283752a3d6d60d43613173bd8af42-lib/lib/libbtor2parser.so (0x00007effe9999000)
            libgmp.so.10 => /nix/store/0h2qlf5y50h7g3ir92pr91sjig6nhdhp-gmp-with-cxx-6.2.1/lib/libgmp.so.10 (0x00007effe98f9000)
            libstdc++.so.6 => /nix/store/sm14bmd3l61p5m0q7wa5g7rz2bl6azqf-gcc-12.2.0-lib/lib/libstdc++.so.6 (0x00007effe96d3000)
            libm.so.6 => /nix/store/dg8mpqqykmw9c7l0bgzzb5znkymlbfjw-glibc-2.37-8/lib/libm.so.6 (0x00007effe95f3000)
            libgcc_s.so.1 => /nix/store/sm14bmd3l61p5m0q7wa5g7rz2bl6azqf-gcc-12.2.0-lib/lib/libgcc_s.so.1 (0x00007effe95d0000)
            libc.so.6 => /nix/store/dg8mpqqykmw9c7l0bgzzb5znkymlbfjw-glibc-2.37-8/lib/libc.so.6 (0x00007effe93ea000)
            /nix/store/dg8mpqqykmw9c7l0bgzzb5znkymlbfjw-glibc-2.37-8/lib64/ld-linux-x86-64.so.2 (0x00007effe9b2d000)

    [nix-shell:/nix/store/ms3p2368syy33q1ac4ln2mk823h3g0a0-boolector-3.2.2/lib]$
