======================================
 NixOS 68: Overriding a Python Package
======================================

- Companion to video at

- This text script available via link in the video description.

- See the other videos in this series by visiting the playlist at
  https://www.youtube.com/playlist?list=PLa01scHy0YEmg8trm421aYq4OtPD8u1SN

The Problem
===========

The tests of a particular Python package are failing, and it is preventing my
build from working.

I would like to use a version whose tests don't fail.  But if I can't find one,
in reality, the test failure is in a part of the code that my project doesn't
execute, so I could get away with telling the package to skip the tests and
allow the build to proceed.

The Solutions
=============

We can solve the problem one of three ways:

- Prevent the offending Python package from running its tests (ok)

- Fix the build such that the tests can pass (better)

- Update the offending Python package to a newer revision whose tests don't
  fail (best)

We'll use the package ``python311Packages.vncdo`` as a test subject.

Prevent the Python Package From Running Its Tests (ok)
------------------------------------------------------

We can use an overlay to change the definition of the offending Python package
so that it doesn't run the tests:

.. code-block:: nix

  overlays = (self: super: {
      python311 = super.python311.override {
        packageOverrides = pyself: pysuper: {
          vncdo = pysuper.vncdo.overrideAttrs (_: {
            setuptoolsCheckPhase = "true";
            doCheck = false;
          });
        };
      };
    });

``doCheck = false;`` by itself is supposed to prevent the tests from executing,
but I found, in practice, that it does not.  However, setting
``setuptoolsCheckPhase`` to the *string* ``true`` (not the boolean value)
indeed does, because that causes the test phase to just execute the ``true``
command on the path (it actually mans "don't execute the tests) instead of the
normal test command.

That works.

Fix the Build Such That The Tests Pass (better)
-----------------------------------------------

But we are wracked with guilt.  Maybe we can fix the build such that the tests
pass.  The original error indicates that it just can't find ``pip``, so we can
add ``pip`` to the PYTHONPATH by changing the ``preCheck`` phase.

.. code-block:: nix

  overlays = (self: super: {
      python311 = super.python311.override {
        packageOverrides = pyself: pysuper: {
          vncdo = pysuper.vncdo.overrideAttrs (_: rec {
            preCheck = "export PYTHONPATH=$PYTHONPATH:${super.python311Packages.pip}/lib/python3.11/site-packages";
          });
        };
      };
    });

But nope.

Upgrading To A Version Whose Tests Pass (best)
----------------------------------------------

Maybe they fixed this upstream:

.. code-block:: nix

  overlays = (self: super: {
      python311 = super.python311.override {
        packageOverrides = pyself: pysuper: {
          vncdo = pysuper.vncdo.overrideAttrs (_: rec {
            version = "1.3.0";
            src = self.fetchFromGitHub {
              owner = "sibson";
              repo = "vncdotool";
              rev = "2b5f10c2115a695b3d106d70bd2ed461a6e60c74";
              hash = "";
             };
          });
        };
      };
    });

Nope.  Let's try to add back in the ``preCheck``.

.. code-block:: nix

  overlays = (self: super: {
      python311 = super.python311.override {
        packageOverrides = pyself: pysuper: {
          vncdo = pysuper.vncdo.overrideAttrs (_: rec {
            version = "1.3.0";
            src = self.fetchFromGitHub {
              owner = "sibson";
              repo = "vncdotool";
              rev = "2b5f10c2115a695b3d106d70bd2ed461a6e60c74";
              hash = "";
             };
           preCheck = "export PYTHONPATH=$PYTHONPATH:${super.python311Packages.pip}/lib/python3.11/site-packages";
          });
        };
      };
    });

Yup.
