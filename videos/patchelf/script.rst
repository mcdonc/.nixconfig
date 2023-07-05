NixOS 45: Dynamic Library Linking Under NixOS: How Do It Work?
==============================================================

- Companion to video at 

- See the other videos in this series by visiting the playlist at
  https://www.youtube.com/playlist?list=PLa01scHy0YEmg8trm421aYq4OtPD8u1SN

Video Script
------------

- What we are about to discuss solves a whole category of problems that are
  collectively known as "DLL hell".  DLL hell exists because only one canonical
  copy of a shared library is typically imagined to exist on a system at any
  given time.  However, contracts between software change, and a newer library
  may not be compatible with older binaries.  Or an older library may not be
  compatible with newer binaries.

- The salvation from DLL hell that Nix gives us is why you can install Nix on
  most any Linux or MacOS platform and install some majority of the 80,000
  packages in the nixpkgs repository, and have confidence that they will work
  and won't be broken incidentally by anything you do to the host system.

- It's why you can often install eight-year-old Nix software on a distribution
  that is one month old.  It's why you can often install one-month-old Nix
  software on a distribution that is eight years old.  At least if ABI
  compatibility is maintained across time in these distributions.
  
- For the record, this is obnly about C/C++ dynamic libraries using the
  GNU toolchain.  I don't know beans about other languages/toolchains that
  support dynamic libraries.

- Going to assume you have some experience compiling C/C++ software from source
  on other platforms.

- The 20,000 foot view:

  - Nix does awesomely insane things to help you build software that you can
    install non-globally more easily.  "Non-globally" means that multiple
    versions of the software you're building can exist on the system
    simultaneously, and each version can have different build-time and runtime
    dependencies.

  - When you build a Nix derivation, it will depend on exactly the versions of
    the build inputs you provide.  Nix derivations name their build inputs via
    the arguments to ``stdenv.mkDerivation`` named ``buildInputs``,
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
    ``gcc`` is always a build input (although most often implicitly), but it
    will rarely become a runtime dependency.

  - To detect actual runtime dependencies, after the software is built, Nix
    scans all the files in the binary output(s) of a derivation to determine
    which packages in your build inputs are needed at runtime.  It literally
    just kinda greps your derivation's output for ``/nix/store`` plus each
    build input's *hash*.  For example if ``curl-8.0.1`` is a build input and
    the derivation of the version of ``curl`` you're depending on has a hash of
    ``03j8nhpi7vj9xl2pxkrxkf62viwxsaz8``, if scanning sees the string
    ``/nix/store/03j8nhpi7vj9xl2pxkrxkf62viwxsaz8`` in any file in the output,
    it will consider ``/nix/store/03j8nhpi7vj9xl2pxkrxkf62viwxsaz8-curl-8.0.1``
    a runtime dependency (the ``curl-8.0.1`` bit is superfluous to dependency
    detection, useful only to humans).  If a build input's hash is found in any
    output, it is a runtime dependency.  If it's not, it isn't.
    
    https://stackoverflow.com/questions/34769296/build-versus-runtime-dependencies-in-nix
    and
    https://lethalman.blogspot.com/2014/08/nix-pill-9-automatic-runtime.html

  - Things that are in your derivation's build inputs whose nix-store-hashes
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
    dependency).  These are stripped out.  This is known as "shrinking" the
    RPATH.

  - Patchelf https://github.com/NixOS/patchelf is used to do both the initial
    RPATH writing and its shrinking.
    
  - ``autoPatchelfHook``
    https://github.com/NixOS/nixpkgs/blob/master/pkgs/build-support/setup-hooks/auto-patchelf.sh
    is a thing we can put in our built inputs that will do all of this
    magically for us.  If it is included as a build input, it will call
    ``patchelf`` at the end of the build process.

