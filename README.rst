Common system config for Chris' various jawns
=============================================

A common, version-controlled set of system configurations for various NixOS
systems I own.

Usage
-----

- Check out this repository into ``~/.nixconfig`` within the NixOS installer on the
  new system::

    cd
    git clone https://github.com/mcdonc/.nixconfig.git

- Run the ``prepsystem.sh`` script.  The first argument should be the device
  name to prepare (e.g. ``/dev/nvme1n1`` or ``/dev/sda``).  The second --
  optional -- argument allows the partition names created to have a suffix (in
  case you're installing a second Nix on a system that already has one device
  formatted with the defaults).::

    ~/.nixconfig/prepsystem.sh /dev/nvme1n1

- This will mount the prepared system on ``/mnt``.

- Copy the ``~/.nixconfig`` directory into ``/mnt/etc/nixos``::

    cd
    sudo cp .nixconfig /mnt/etc/nixos

- Move the system-generated ``/mnt/etc/nixos/configuration.nix`` aside::

    sudo mv /mnt/etc/nixos/configuration.nix{_aside}

- If necessary, copy one of the existing ``thinknix*`` directories (or the
  ``vanilla`` directory) into another, creating a new system.  Remember to
  change the hostId and hostName, if so.

- Link the ``configuration.nix`` representing the new system into
  ``/mnt/etc/nixos/configuration.nix``::

    sudo ln -s /mnt/etc/nixos/.nixconfig/thinknix512/configuration.nix /mnt/etc/nixos

- Install the system::

     sudo nixos-install

- Reboot.

Post-Reboot
-----------

- Check out this repo on the new vanilla system into ``~/.nixconfig``::

    git clone git@github.com:mcdonc/.nixconfig.git

- *or* copy it from /etc/nixos/.nixconfig into the homedir if you've created a
  new system::

    cp -r /etc/nixos/.nixconfig ~
    
