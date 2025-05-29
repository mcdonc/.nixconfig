Editing Secrets
---------------

To edit an existing secret::

   agenix -e pjsip.conf.age

To add a new secret, edit ``secrets.nix`` and add it, e.g.::

   "pjsip.conf.age".publicKeys = [ chrism lock802 ];

Then edit it.

To rekey all secrets after changing pubkeys of a secret::

  agenix --rekey

