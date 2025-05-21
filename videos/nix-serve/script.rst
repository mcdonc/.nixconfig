NixOS 101: Using ``nix-serve`` as a Local Binary Cache
======================================================

- Companion to video at ...
  
- See the other videos in this series by visiting the playlist at
  https://www.youtube.com/playlist?list=PLa01scHy0YEmg8trm421aYq4OtPD8u1SN

About
-----

Do you use NixOS/Nix on more than one system?  When you update or add the same
software to each of them, does it set your teeth on edge to see each redownload
and recompile gigabytes of software from the Internet?

`nix-serve <https://github.com/edolstra/nix-serve>`_ will serve up one of your
systems' ``/nix/store`` as a Nix binary cache.  You can then configure your
other systems to use the server as a "substituter."  They will try to pull
changes from your server before trying to download from sources on the
Internet.  Those systems will rarely need to compile any software if their
configuration is a lot like the server's, because the server will have done it
already.

Most of my systems have the same general configuration, each deviating only
slightly based on its role. So as long as I remember to update and rebuild the
``nix-serve`` server config first, subequent builds done on the ``nix-serve``
clients mostly operate completely locally, without any downloading over the
Internet and without doing any compilation.

Caveat Emptor
-------------

There are some significant downsides to using ``nix-serve`` or any substituter
that serves up the same set of files as ``cache.nixos.org``.

Don't do a ``sudo nix-collect-garbage -d`` just whilst making changes to any of
the systems involved in this process, and for a while afterwards. Doing this
will prevent you from booting from an earlier NixOS generation, and it's pretty
easy to find yourself there if you make a mistake or you run into a Nix bug
while messing around with this stuff.

For example, if you run into `this Nix bug
<https://github.com/NixOS/nix/issues/8254#issuecomment-1809046508>`_ you won't
even be able to run ``nixos-rebuild`` to disable your client's ``nix-serve``
configuration, so you'll be stuck in that configuration without rolling back
using the generation system.

If the server dies, or if you take any of the client machines to a place where
the server is uncontactable, you might run into similar situations, or at least
I did.  This may make it infeasible to use as clients laptops that can't
connect to the server from the road using the same hostname as when they're on
the same network.  I really don't understand why this is the case, and why it
doesn't just skip the missing substituter.  I'm just reporting from the field.

A similar situation on the server may occur if you paste a malformed private
key into the server's configuration.

Server
------

On the NixOS system you'd like to use as the server, run the following
commands::

  $ sudo su -
  # cd /
  # nix-store --generate-binary-cache-key "nix-serve-$(hostname -s)" \
      nix-serve-private nix-serve-public

Then add the service configuration to its ``configuration.nix``:

.. code-block:: nix

   services.nix-serve.enable = true;
   services.nix-serve.secretKeyFile = "/nix-serve-private";

Then run ``nixos-rebuild switch``.

You can test that the new service is running by executing
``systemctl status nix-serve.service``.

``nix-serve`` can also be run `on non-NixOS machines
<https://github.com/edolstra/nix-serve>`_ although configuration is more
manual.

Clients
-------

In each client's ``configuration.nix`` (replace ``yourserver`` with the DNS
name or IP address of the server you configured above):

.. code-block:: nix

   nix.settings.substituters = [ "http://<yourserver>:5000" ];
   nix.settings.trusted-substituters = [ "http://<yourserver>:5000" ];
   nix.settings.trusted-public-keys = [ "nix-store-<yourserver>:wnd5de..." ];
   
The value of the item in ``nix.settings.trusted-public-keys`` should be the
contents of ``/nix-serve-public`` from the server.  Be careful to paste
this value exactly, as adding a malformed trusted public key can make it
impossible to execute ``nixos-rebuild`` subsequently, forcing you to boot from
a prior generation to fix it.

Run ``nixos-rebuild switch``.

Note that this will also work on non-NixOS systems that use Nix.  On those, you
max need to add the equivalent values to ``/etc/nix/nix.conf`` instead of
putting them in any Nix file.

Testing
-------

To see the log of the ``nix-serve`` service, invoke this on the server::

  sudo journalctl -f -u nix-serve.service

Now let's get some software downloaded onto the server that doesn't yet exist
on either the server or the client.

Run this on the server::

  nix-shell -p dwarf-fortress

It will need to compile the ``dwarf-fortress`` software.

Once it's finished, run the same on the client.

You should see the server's nix-serve.service log grow, and you should see
``dwarf-fortress`` and its dependencies being downloaded from your server
instead of from ``cache.nixos.org`` in the output of ``nixos-rebuild switch``.
It will not need to be compiled.

To test that signing and signature verification between the server and client
is working, from a properly configured client, you should be able to do
something like this (change hostname to your server's and the nix store path to
something that exists in the server's ``/nix/store/``)::
  
  nix store verify --store http://keithmoon:5000/ \
    /nix/store/64v9rlzbiai9h116sjydjj4f9yh5dx8w-dwarf-fortress-51.11

It should not return anything that says "untrusted", at least for software
added to the server's Nix store after you set up ``nix-serve``.

Notes
-----

You might notice that we put the server's private key in the root
directory.  It doesn't really matter where it goes, it just needs to exist when
the ``nix-serve.service`` starts.  The need only be readable by the root user
because ``systemd`` runs as root and takes care of supplying it to the service
as a `credential <https://systemd.io/CREDENTIALS/>`_.

The ``nix-serve`` service will run as a "dynamic" user.  ``systemd`` will
create a ``nix-serve`` user when it starts, and the user is deleted when it
stops.

By observation, at least, files that were present in the ``nix-serve`` server's
``/nix/store`` before you configured ``nix-serve`` will not be trusted by
clients.  Those will need to be downloaded from ``cache.nixos.org`` and you'll
see irritating "not trusted" messages in the output of ``nixos-rebuild``.

Other Options
-------------

I tried `Peerix <https://github.com/cid-chan/peerix>`_ but failed to get it
working.  I experienced the symptoms described in `this GitHub issue
<https://github.com/cid-chan/peerix/issues/9>`_.

It would be great if Peerix worked, because, at least in my imagination, it
would be kinda like Steam's ambient local download configuration where any
local machine would be willing to download from any other local machine that
has the data, instead of needing to dedicate one as a server and the others as
clients.

There is also `Harmonia <https://github.com/nix-community/harmonia>`_.  I
haven't yet tried it.  It works a lot like ``nix-serve`` except with more
features, like inbuilt TLS and better streaming (but not peering).
