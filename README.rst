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

- Move the system-generated ``/mnt/etc/nixos`` aside::

    sudo mv /mnt/etc/nixos /mnt/etc/nixos_aside

- Copy the ``~/.nixconfig`` directory on top of ``/mnt/etc/nixos`` (not *into*
  it, it should *become* ``/mnt/etc/nixos``)::

    cd
    sudo cp .nixconfig /mnt/etc/nixos

- If necessary, copy one of the existing ``/mnt/etc/hosts/thinknix*.nix`` files
  (or the ``vanilla.nix`` file) into another within the
  ``/mnt/etc/nixos/hosts`` directory, creating a new system.  Remember to
  change the ``hostId`` and ``hostName``, if so.

- Link the nixfile representing the new system into
  ``/mnt/etc/nixos/configuration.nix``::

    sudo ln -s /mnt/etc/nixos/hosts/thinknix51.nix /mnt/etc/nixos/configuration.nix

- Install the system::

     sudo nixos-install

- Reboot.

Post-Reboot
-----------

- Change your user's password.

- Change ownership of ``/etc/nixos`` (this used to be ``/mnt/etc/nixos`` before
  the reboot) to the name of the user you created by virtue of installing Nix.::

    sudo chown -R chrism:users /etc/nixos

