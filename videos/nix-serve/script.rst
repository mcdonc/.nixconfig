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
other systems to use that server as a "substituter", aka binary cache.  When
configured that way, your other systems will try to pull changes from your
server before trying to download from sources on the Internet.

Server
------

On the NixOS system you'd like to use as the server, run the following
commands::

  $ sudo su -
  # cd /root
  # nix-store --generate-binary-cache-key "nix-serve-$(hostname -s)" \
      nix-serve-private nix-serve-public

Then add the service configuration to its ``configuration.nix``:

.. code-block:: nix

   services.nix-serve.enable = true;
   services.nix-serve.secretKeyFile = "/root/nix-store-private";

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
contents of ``/root/nix-store-public`` from the server.  Be careful to paste
this value exactly, as adding a malformed trusted public key can make it
impossible to execute ``nixos-rebuild`` subsequently, forcing you to boot from
a prior generation to fix it.

Run ``nixos-rebuild switch``.

Note that this will also work on non-NixOS systems that use Nix.  On those, you
max need to add the equivalent values to `/etc/nix/nix.conf` instead of putting
them in any Nix file.

Testing
-------

To see the log of the ``nix-serve`` service, invoke this on the server::

  sudo journalctl -f -u nix-serve.service

Now let's get some software downloaded onto the server that doesn't yet exist
on either the server or the client.  Maybe add something like ``blender`` or
some other large software package that you probably don't already use to
``environment.systemPackages`` on the server.

Then rerun its ``nixos-rebuild``.

The, on the client, change its ``configuration.nix`` to also add ``blender`` to
``environment.systemPackages``.

Then run ``nixos-rebuild switch`` on the client.

You should see the server's nix-serve.service log grow, and you should see
``blender`` and its dependencies being downloaded from your server instead of
from ``cache.nixos.org`` in the output of ``nixos-rebuild switch``.

To test that signing and signature verification between the server and client
is working, from a properly configured client that you should be able to do
something like this (change hostname to your server's and the nix store path to
something that exists in the server's ``/nix/store/``)::
  
  nix store verify --store http://keithmoon:5000/ \
    /nix/store/lk4qvlshidc6lxa4ig8yixzkf6x6j488-firefox-138.0.3

It should not return anything that says "untrusted".

Other Options
-------------

I tried `Peerix <https://github.com/cid-chan/peerix>`_ but failed to get it
working.  I experienced the symptoms described in `this GitHub issue
<https://github.com/cid-chan/peerix/issues/9>`_.

It would be great if Peerix worked, because it would be kinda like Steam's
ambient local download configuration where any local machine would be willing
to download from any other local machine that has the data, instead of needing
to dedicate one as a server and the others as clients.

There is also `Harmonia <https://github.com/nix-community/harmonia>`_.  I
haven't yet tried it.  It works a lot like ``nix-serve`` except with more
features, like inbuilt TLS and better streaming (but not peering).
