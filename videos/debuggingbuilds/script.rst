NixOS 46: Debugging A Failing Build
===================================

- Companion to video at

- See the other videos in this series by visiting the playlist at
  https://www.youtube.com/playlist?list=PLa01scHy0YEmg8trm421aYq4OtPD8u1SN

Overview
--------

- This video script available via link in the description.

- Nix allows few compromises when it comes to building software from source.
  It pretty much forces you to actually fix the software which you're building
  such that it can be built within a reproducible environment.

- This often makes packaging software for Nix/NixOS tricky and frustrating.  It
  can be a maddeningly eat-your-vegetables affair.  It's also makes the result
  very stable, because once it has been done, the result is highly likely to
  work on any system and "stays finished."

- "Works On My Machine"(TM) is not a thing in Nix unless you work pretty hard
  at it.

- Here, we will take a look at how to debug a very specific failing build.

Sandboxing
!!!!!!!!!!

- For a few years now, NixOS has enabled "sandboxed builds" of software
  realized via ``stdenv.mkDerivation``.  It is actually a feature of Nix,
  rather than NixOS.

- Sandboxes have limited access to build system resources.  A sandbox is a
  chroot environment with only the minimum number of essential system files and
  utilities necessary (e.g. ``/etc/passwd``, ``/bin/sh``, etc), no remote
  network access, and a ``/nix/store`` that contains only the packages
  specified by the derivation's build inputs.  *Note: it is not a container*.

- Rationale: if builds are permitted to access files and network addresses
  outside of the sandbox, any given build cannot be considered reproducible.
  If sandboxing is disabled and a given build succeeds on your system, it is
  possible (and even likely) that it would not succeed on someone else's.

- See this excellent presentation by Mic92 (the primary implementor of
  sandboxed builds) for some extra details:

  https://www.youtube.com/watch?v=ULqoCjANK-I&pp=ygUNbWljOTIgc2FuZGJveA%3D%3D
 
Debugging
!!!!!!!!!

- Given Nix's build-time restrictions, and the typical developer's lack of
  knowledge that they might be violating Nix-related build restrictions in the
  software they create, there is a 100% chance that some software that builds
  without issue on a given release of, say, Ubuntu will not succeed within the
  Nix ecosystem.  When these fail, we need ways to debug and fix them.

- There are a number of strategies you can use to debug failing builds:

  - Temporarily turn off sandboxing

  - ``breakpointHook`` and ``cntr``

  - ``LD_DEBUG=libs`` (for shared library problems)

  - ``nix-shell``

  - ``sysdig``

Aside: Nix-expression Impurities
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

- There are even more restrictions about the build environment than a sandbox:
  Nix won't allow you to add things to your derivation-expressions that are
  "impure" by default.  Most notably, without a command flag, your derivation
  must not contain any ``<bracketed>`` names such as ``<nixpkgs>`` because this
  implies a reliance on the ``NIX_PATH`` environment variable, which may change
  per-system.

- These are typically easy to debug, because the system just won't start the
  build if you have these names in an expression file and you try to evaluate
  the expression in pure mode.  Use ``--impure`` as a flag to ``'nix-build`` to
  temporarily work around it.

- To permanently work around it, you'll need to change your Nix derivation
  expression.

- You'll often see ``--impure`` and the disabling of sandboxing used together,
  but they are logically distinct.

Turning Off Sandboxing to Debug a Failing Build
-----------------------------------------------

- Sandboxing can be turned off on a per-build basis.  This is the heavy-handed
  way to easily check if restrictions in the sandbox are preventing the build
  from succeeding.

- If the build succeeds when you disable the sandboxing, at least you know it's
  due to sandbox restrictions, and you can then begin to investigate what's
  different between the sandbox environment and the non-sandboxed environment

- To turn off sandboxed builds, use the value ``--option sandbox false`` as an
  argument to ``nix-build``.

- In order for this to suceed as a normal user, you will need this somewhere in
  your active NixOS configuration::

    nix.extraOptions = ''
      trusted-users = root @wheel
    '';
    
- Once that is done, any user in the ``wheel`` UNIX group will be permitted to
  use the ``--option sandbox false``.  You can put a user (imagine your
  username is chrism) in the ``wheel`` group by doing this somewhere in your
  NixOS configuration::

    users.user.chrism.extraGroups = [ "wheel" ]
  
Demo
!!!!

- I want background blur because my camera background environment is typically
  a superfund disaster.

- ``obs-backgroundremoval`` plugin has a Nix presence and it works.  Out of the
  box, Nix lets you use the 0.5.7 version of it.

- But older version (0.5.7) uses CPU-only rendering and consumes 100% of every
  one of my cores when running.  This is not useful.

- The latest version (1.0.3) has GPU rendering, but has a newer dependency
  (``onnxruntime`` went from ``1.13.1`` to ``1.14.1``).

- "How hard could it be to do the upgrade?  Should be done in 15 minutes!"
  Nah.  Weeks.

- Newer version of ``onnxruntime`` is not in nixpkgs.  It also builds very
  differently.  The newer version of ``obs-backgroundremoval`` also uses a
  feature of ``onnxruntime`` not exposed by the current packaging of
  ``onnxruntime`` 1.13.1 in Nix at all ("tensorrt" support).  ``onnxruntime``
  is useful on its own without TensorRT but ``obs-backgroundremoval`` requires
  it, so it's not useful to me without it.  I just wanted a Pepsi and she
  wouldn't give it to me.

- My first attempts at the upgrade via overlays were unsuccessful.  I couldn't
  get ``onnxruntime`` to build at all.  So I created my own version of the
  nixpkgs ``onnxruntime`` derivation for hacking purposes and made a new
  ``obs-backgroundremoval`` derivation that depends on it.

  .. note::

     This is not idiomatic Nix code, I'm not experienced enough to write such a
     thing.

- Many, many changes to those files later, I finally achieved a good build (the
  ``buildPhase`` succeeded), but the test suite puked (the ``checkPhase``
  failed).

- During the build, we see innumerable errors like these being thrown during
  the running of the unit tests (the "check" phase)::

   CUDA failure 35: CUDA driver version is insufficient for CUDA runtime
   version ; GPU=0 ; hostname=localhost ; expr=cudaSetDevice(info_.device_id);

- Research shows that this error is reached when either when the NVIDIA GPU
  driver version doesn't match the CUDA driver version (as is printed on the
  error message tin) *or* if the driver isn't installed at all.

- "Driver not installed at all" sounds suspiciously like it could be a symptom
  of Nix build sandboxing.

- I debugged the failing test suite of ``onnxruntime-1.14.1`` by turning off
  sandboxing.

- Before turning off sandboxing::

    NIXPKGS_ALLOW_UNFREE=1 --expr 'with import <nixpkgs> {}; callPackage ./onnxruntime.nix {}'

  After::

    NIXPKGS_ALLOW_UNFREE=1 nix-build --option sandbox false --expr 'with import <nixpkgs> {}; callPackage ./onnxruntime.nix {}'

  (the NIXPKGS_ALLOW_UNFREE=1 envvar is necessary for some CUDA builds).

  .. note::

     ``with import <nixpkgs>`` won't work on flakes-based NixOS systems unless
     you define a ``nixos`` channel.

- Lo and behold, when we build without a sandbox, we still have test failures,
  but many fewer, and but none of them are "CUDA driver is insufficent..."
  errors.  So we know that at least part of our issue is the ``nix-build``
  sandboxing.

- Now, I don't really want to turn off sandboxed builds for
  ``obs-backgroundremoval`` because if I did, I'd have to think about it on
  each of my systems and employ some hacks as workarounds.  I know I'm not
  smart enough to deal with a "Works On One Of My Machines" situation, because
  I'll inevitably forget how to make it work via hackery, and thus it will be
  useless to me.  So, either I have to turn off the test suite if I know the
  plugin works despite the test failures (that's "good enough" here for me), or
  I have to get sandboxed builds of CUDA crap working to get the tests passing.

- So I just turned off the tests (``doCheck=false;``) to see if the background
  blur plugin would work despite the failures.  I'm not doing software
  engineering here, I just want background blur.  But nope.  Back to tests
  turned on.

- Back to trying to get the tests to pass.

Using ``breakpointHook`` and ``cntr``
-------------------------------------

- We know now that the sandbox environment and its interaction with shared
  libraries has at least something to do with some of the test failures.

- We can attempt to change our derivation such that we apply extra patches,
  use different dependency versions, use different compile flags, etc.

- But sometimes compile times make this prohibitive.  Also, by the way, the
  build environment is also deleted after the build fails.

- To tell our build to pause before it exits so we can take a look at the
  sandbox itself, we can use the ``breakpointHook`` build input.

Demo
!!!!

- But the build of ``onnxruntime-1.14.1`` consumes about 50 minutes on my
  octo-core Thinkpad P51.  ``nix-build`` will start from scratch every time we
  make a change to our derivation file and rerun it.  This makes incremental
  attempts to fix the build very inefficient.

- We need to add ``cntr`` to our global applications list to have it available
  when we need it.

- We add ``breakpointHook`` to our expression file's arguments.

- Put that in our ``nativeBuildInputs`` and rerun the build.

- It spits out a ``cntr`` command that we can use for the first stage of
  reaching the sandbox.  Run it under ``sudo``.

- Once connected via cntr, run ``cntr exec`` to enter the sandbox.

- We find that ``/run/opengl-drivers/lib`` (aka addOpenGLRunpath.driverLink)
  doesn't exist in the sandbox.  That's why our tests can't work.  Thus, the
  ``onnxruntime`` tests will never pass under the sandbox, because it needs to
  find the NVIDIA drivers, which will never exist there.  Theory confirmed.

- So I'll continue to disable the sandbox as we try to make the tests pass.  If
  I can get the tests passing without the sandbox, and I get
  ``obs-backgroundremoval`` working under the resulting environment, I'll just
  disable the tests (again, not doing software engineering here, not trying to
  contribute this to nixpkgs, just trying to get background blur).

Turning Sandboxing Back On and Using ``LD_DEBUG=lib``
-----------------------------------------------------

- When stuff doesn't work, it's often enlightening to run the offender under
  ``strace`` to see what the hell is happening under the hood.

- It is difficult to use ``strace`` in complex builds when something fails.  In
  our case, ``onnxruntime`` uses the CMake build system, and CMake declarations
  dictate both how the software is built and how the tests are run.  Both
  during the build and test phase, multiple processes are launched to chomp
  down the work, out of direct control of the developer.  Injecting a strategic
  ``strace`` is impractical due to this.

- But the GNU loader respects an environment variable named ``LD_DEBUG``.  If
  you set it to ``LD_DEBUG=libs`` it will show the paths it searches for shared
  libraries, and you can kinda divine which shared lib it found for some bit of
  code (such as a test).

- Since our failures are during test time, and not during build time, and due
  to the kinds of errors spewing on the console, we can make an educated guess
  that using shared libraries is our issue.  ``LD_DEBUG=libs`` gives us some
  visibility into which shared libraries are being found during the test suite.

Un-parallelizing builds
!!!!!!!!!!!!!!!!!!!!!!!

- Projects built with CMake allow you to specify ``enableParallelBuilding =
  true;`` to parallelize both the build and the tests.

- For debugging sanity, it should be turned off if it's on.
  ``enableParallelBuilding = false;``

Using CUDA stubs
!!!!!!!!!!!!!!!!

- Some research implies that it is possible to use "stub" CUDA libraries to
  compile on machines that don't actually have a CUDA driver installed.  This
  is unlikely to fix our problem because the stub libraries just raise errors
  when you try to use them, and the tests use libraries, they don't just
  compile against them.

- But what the hell, why not try it.

- After we begin to use stubs during the test suite, we still have the same
  number of errors, but the errors change.  In particular, the
  CUDA-lib-related errors change from::

    CUDA failure 35: CUDA driver version is insufficient for CUDA runtime
    version ; GPU=0 ; hostname=localhost ; expr=cudaSetDevice(info_.device_id);

  To::

    CUDA failure 34: CUDA driver is a stub library ; GPU=0 ; hostname=localhost
    ; expr=cudaSetDevice(info_.device_id);

- This isn't much progress, but it does at least verify that the bits of the
  code we changed were in the right place, and gives us more confidence that
  this isn't just a "libraries not found" situation while in the sandbox.

Using nix-shell
---------------

I did not use this strategy but it is possible to use a ``nix-shell`` to
manually invoke the stages of a build instead of using ``breakpointHook`` and
``cntr``. See
https://discourse.nixos.org/t/debug-a-failed-derivation-with-breakpointhook-and-cntr/8669
(jongringer's follow-up comment).

However, I don't think this will exercise the sandbox machinery.

Using ``sysdig``
----------------

I did not use this strategy but it is possible to use ``sysdig`` in conjunction
with ``breakpointHook`` and ``cntr`` to see all of the syscalls made during the
build and check phases (sort of like a super-``strace``) to see why it might be
failing.  There is a brief overview of how this can be done in Mic92's
presentation about ``breakpointHook`` at
https://www.youtube.com/watch?v=ULqoCjANK-I&pp=ygUNbWljOTIgc2FuZGJveA%3D%3D

This can be used instead of (or in concert with) ``LD_DEBUG``.
