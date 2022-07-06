Common system config for Chris' various jawns
=============================================

A common, version-controlled set of system configurations for various NixOS
systems I own.

Usage
-----

Initialize a new system.

- ``export ROOTDEV=/dev/nvmeXnX``

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

   sudo mkfs.fat -F 32 ${ROOTDEV}p1
   sudo fatlabel ${ROOTDEV}p1 NIXBOOT

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
    ${ROOTDEV}p2

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
   sudo mount ${ROOTDEV}p1 /mnt/boot
   sudo mount -t zfs NIXROOT/home /mnt/home

- Generate the initial config::

    sudo nixos-generate-config --root /mnt

- Copy ``vanilla.nix`` from this repo on top of
  ``/mnt/etc/nixos/configuration.nix`` and edit (change ``networking.hostId`` and
  ``networking.hostName``)

- Install the system::

     sudo nixos-install

- Reboot.

Post-Reboot
-----------

- On the new vanilla system, add these channels as the root user::

   sudo nix-channel --add https://github.com/nix-community/home-manager/archive/release-22.05.tar.gz home-manager
   sudo nix-channel --add https://github.com/NixOS/nixos-hardware/archive/master.tar.gz nixos-hardware

- Update the newly added channels::

    sudo nix-channel --update

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
