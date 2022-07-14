Common system config for Chris' various jawns
=============================================

A common, version-controlled set of system configurations for various NixOS
systems I own.

Usage
-----

Initialize a new system.

- ``export ROOTDEV=/dev/nvmeXnX``

- ``export ROOTDEVPREFIX=${ROOTDEV}p``

- ``sudo sgdisk --zap-all $ROOTDEV``

- ``sudo fdisk $ROOTDEV``, then::

    g
    n
    accept default part num
    accept default first sector
    last sector: +2G
    t
    use partiton type 1 (EFI System)
    n
    accept default partition number
    accept default first sector
    accept default last sector
    w

- No swap partition (huge amount of memory, also security)

- Create the boot volume::

   sudo mkfs.fat -F 32 ${ROOTDEVPREFIX}1
   sudo fatlabel ${ROOTDEVPREFIX}1 NIXBOOT

- Create a zpool::

    sudo zpool create -f \
    -o altroot="/mnt" \
    -o ashift=12 \
    -o autotrim=on \
    -O compression=lz4 \
    -O acltype=posixacl \
    -O xattr=sa \
    -O relatime=on \
    -O normalization=formD \
    -O dnodesize=auto \
    -O sync=disabled \
    -O encryption=aes-256-gcm \
    -O keylocation=prompt \
    -O keyformat=passphrase \
    -O mountpoint=none \
    NIXROOT \
    ${ROOTDEVPREFIX}2

- Create zfs volumes::

   sudo zfs create -o mountpoint=legacy NIXROOT/root
   sudo zfs create -o mountpoint=legacy NIXROOT/home
   # reserved to cope with running out of disk space
   sudo zfs create -o refreservation=1G -o mountpoint=none NIXROOT/reserved

- Mount the NIXROOT/root volume under ``/mnt``::

   sudo mount -t zfs NIXROOT/root /mnt

- Mount subvolumes::

   sudo mkdir /mnt/boot
   sudo mkdir /mnt/home
   sudo mount ${ROOTDEVPREFIX}1 /mnt/boot
   sudo mount -t zfs NIXROOT/home /mnt/home

- Generate the initial config::

    sudo nixos-generate-config --root /mnt

- Copy ``vanilla.nix`` from this repo on top of
  ``/mnt/etc/nixos/configuration.nix`` and edit (change ``networking.hostId`` and
  ``networking.hostName``)::

    cp ~/.nixconfig/vanilla.nix /mnt/etc/nixos/configuration.nix

- Install the system::

     sudo nixos-install

- Reboot.

Post-Reboot
-----------

- Check out this repo on the new vanilla system into ``~/.nixconfig``::

    git clone git@github.com:mcdonc/.nixconfig.git

- Copy an existing system from ``~/.nixconfig/<existingsystemname>`` into
  ``~/.nixconfig/<newsystemname>`` and edit the ``configuration.nix`` and
  ``hardware-configuration.nix`` files in the newly copied directory, e.g.::

    cp -r thinknix51 newsystemname

- Add a symlink from ``~/.nixconfig/<newsystemname>/configuration.nix`` to
  ``~/.nixconfig/configuration.nix``, e.g.::

     ln -s newsystemname/configuration .

- Rename ``/etc/nixos/configuration.nix{,_aside}`` for safety::

    sudo mv /etc/nixos/configuration.nix{,_aside}

- Test the configuration::

    sudo nixos-rebuild -I nixos-config=$HOME/.nixconfig/configuration.nix dry-activate

- Make the configuration bootable::

    sudo nixos-rebuild -I nixos-config=$HOME/.nixconfig/configuration.nix boot

- Reboot into the version-controlled environment.  Use ``ednix`` to edit the
  current configuration.  Use ``swnix`` to build and switch to an updated
  configuration.
