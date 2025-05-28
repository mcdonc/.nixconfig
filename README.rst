Common system config for Chris' various jawns
=============================================

A common, version-controlled set of system configurations for various NixOS
systems I own.

Usage
-----

- Edit the https://github.com/mcdonc/.nixconfig/blob/master/flake.nix file,
  adding the new system to ``nixosConfigurations``, referencing a file we
  intend to create in the repo's ``hosts`` dir
  (e.g. ``hosts/mynewsystem.nix``) in a subsequent step::

        mynewsystem = nixpkgs.lib.nixosSystem {
          inherit system specialArgs;
          modules = shared-modules ++ [ ./hosts/mynewsystem.nix ];
        };

- Add the ``hosts/mynewsystem.nix`` file, copying another host file to start
  with.  Remember to change the ``hostId`` and ``hostName``.  Use this
  for the hostId::

    openssl rand -hex 4

- Add the following to the ``hosts/mynewsystem.nix`` (bw compat issue)::

     fileSystems."/nix" =
       { device = "NIXROOT/nix";
         fsType = "zfs";
       };

- Check in and push.
    
- Check out this repository into ``~/.nixconfig`` within the NixOS installer on
  the new system::

    cd
    git clone https://github.com/mcdonc/.nixconfig.git

- Run the ``prepsystem.sh`` script.  The first argument should be the device
  name to prepare (e.g. ``/dev/nvme1n1`` or ``/dev/sda``).  The second --
  optional -- argument allows the partition names created to have a suffix (in
  case you're installing a second Nix on a system that already has one device
  formatted with the defaults).::

    sudo ~/.nixconfig/prepsystem.sh /dev/nvme1n1

- This will mount the prepared system on ``/mnt``.

- Move the system-generated ``/mnt/etc/nixos`` aside::

    sudo mv /mnt/etc/nixos /mnt/etc/nixos_aside

- Copy the ``~/.nixconfig`` directory on top of ``/mnt/etc/nixos`` (not *into*
  it, it should *become* ``/mnt/etc/nixos``)::

    cd
    sudo cp -r .nixconfig /mnt/etc/nixos

- Install the system::

     sudo nixos-install  --flake /mnt/etc/nixos#mynewsystem

- Copy the generated ``/mnt/etc/nixos_aside/hardware-configuration.nix`` to a
  safe place to capture what the scanner found that is not yet reflected in the
  checked in config::

    $ passwd   # (change nixos user passwd)
    $ ifconfig # (see ip address)
    
    ssh nixos@<ip address> and cut n paste hardware config, add as comment to
      hosts/mynewsystem.nix

- Reboot.

Post-Reboot
-----------

- Change your user's password.

- Put your private SSH key into ~/.ssh (e.g. ``id_rsa``).  At the next relogin
  you will be prompted by ksshaskpass for its passphrase.  You will also need
  to change the ``kdewallet`` password to the new password you gave your user
  for it to save successfully.

- Change ownership of ``/etc/nixos`` (this used to be ``/mnt/etc/nixos`` before
  the reboot) to your user, so you can commit and pull.::

    sudo chown -R chrism:users /etc/nixos

- Convert the https checkout of ``/etc/nixos`` to an ssh checkout by changing
  ``url = https://github.com/mcdonc/.nixconfig.git`` to ``url =
  git@github.com:mcdonc/.nixconfig.git`` in the ``[remote "origin"]`` section
  of ``/etc/nixos/.git/config``.

- Set up swap space if necessary (change 8GB to whatever)::

   zfs create -V 8G -b 16384 -o compression=zle \
      -o logbias=throughput -o sync=always \
      -o primarycache=metadata -o secondarycache=none \
      -o com.sun:auto-snapshot=false NIXROOT/swap

   mkswap -f /dev/zvol/NIXROOT/swap

   swapon -av

  Add the swap space to swapDevices in the host's Nix config::

   swapDevices = [{ device = "/dev/zvol/NIXROOT/swap"; }];
 
Hosted Machines
---------------

To generate an image for hosted machines::

  nix build ".#nixosConfigurations.arctor.config.formats.do"

Where ``arctor`` is the hostname, and ``do`` (digital ocean) is the format.

To update the configuration remotely::

  nixos-rebuild switch --flake ".#arctor" --target-host chrism@ipaddr --use-remote-sudo

Could use ``security.sudo.wheelNeedsPassword = false;`` to get around password
entry requirements.

lock802 is::

  nix build ".#nixosConfigurations.lock802.config.formats.sd-aarch64"
  nixos-rebuild switch --flake ".#lock802" --target-host chrism@lock802 --use-remote-sudo
