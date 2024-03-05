================================================
NixOS 77: Sane Python Script Generation with Nix
================================================

The ``nixpkgs`` function ``pkgs.writers.writePython3Bin`` is meant to be used
to create an executable Python script with a suitable hashbang within a Nix
environment that can be executed from a command line.

For example, you might write some Nix like this to generate a Python script
that prints hello.  It will be put into a place that is typically on the global
UNIX ``PATH``.

.. code-block:: nix

  mypyscript = pkgs.writers.writePython3Bin "mypyscript" {} ''
    print("hello from a Python script")
  '';

It's usually better to put the Python in an external file, to get the syntax
highlighting offered by your editor:

.. code-block:: nix

   mypyscript = pkgs.writers.writePython3Bin "mypyscript" {}
     (builtins.readFile ./bin/mypyscript.py);

Where ``bin/mypyscript.py`` has the following contents:

.. code-block:: python
              
   print("hello from a Python script")            

Once you've realized this derivation somewhere in your config, you would be
able to run ``mypyscript`` from a shell.

Unfortunately, ``writePython3Bin`` is quite opinionated about the formatting of
the Python it will accept.  For example, changing ``myscript.py`` to this:

.. code-block:: python
              
   print("hello from a Python script")#a comment

Will cause the derivation to not be realizable.

This is because ``writePython3Bin`` uses ``flake8`` to lint the code you feed
it, and ``flake8`` cares not only about executability of the Python, but about
line lengths, numbers of linefeeds between functions, and other things that are
almost always irrelevant for one-off scripts.  Even if they aren't irrelevant,
your own repository's code rules may conflict with the defaults of ``flake8``
that ``writePython3Bin`` uses; for example, the rules enforced by ``black``
conflict with those of ``flake8``.  Even if you don't keep your Python in a
separate file, it's also clown-cars when you try to inline Python code into Nix
and meet these linting requirements because your editor highlighting can't help
you follow linting rules.

You can pass arguments to ``writePython3Bin`` that will disable ``flake8``
rules one-by-one.  For example:

.. code-block:: nix

   mypyscript = pkgs.writers.writePython3Bin "mypyscript"
     { flakeIgnore=["E261"]; }
     (builtins.readFile ./bin/mypyscript.py);

But I haven't been able to tell it to not lint the Python at all, so it can be
a maddening effort of whack-a-mole to generate a Python script that meets the
linting requirements of both ``writePython3Bin`` and your own project
repository if you keep your Python script in an external file.

To work around this, let's disuse ``writePython3Bin``, and use
``substituteAll`` instead.  This solution *requires* that we put our Python in
an external file, rather than inlining it into our Nix.

The Nix:

.. code-block:: nix

  mypyscript = pkgs.substituteAll ({
    name = "mypyscript";
    src = ./bin/mypyscript.py;
    dir = "/bin";
    isExecutable = true;
    py = "${pkgs.python311}/bin/python";
  });

The Python in ``./bin/mypyscript.py``:

.. code-block:: python

   #!@py@
   print("hello from a Python script")

No linting of the Python in ``mypyscript.py`` will be done at derivation
realization time.  If it doesn't work, it will fail at runtime, rather than at
derivation realization time.

The ``dir = "/bin"`` is boilerplate and is required, as is
``isExecutable=true``.  ``src`` is a path that points at a filesystem path
relative to your Nix file.  ``py`` is a variable that will replace ``@py@`` in
the Python file, and we point it at the Nix store path of the default Python
above.

One thing that this doesn't allow us to to do is conveniently specify libraries
only related to the script, like ``writePython3Bin`` does.

.. code-block:: nix

   mypyscript = nixpkgs.writers.writePython3Bin "mypyscript" {
      libraries = with nixpkgs.python3.pkgs; [ pandas ]; } ''
     print("hello from a Python script with pandas")
   '';

To do so, we have to create another Python derivation and use it instead:

.. code-block:: nix

    python-for-mypyscript = (pkgs.python311.withPackages (p:
      with p; [ pkgs.python311Packages.pandas]));
      
    mypyscript = pkgs.substituteAll ({
      name = "mypyscript";
      src = ./bin/mypyscript.py;
      dir = "/bin";
      isExecutable = true;
      py = "${python-for-mypyscript}/bin/python";
    });
    
