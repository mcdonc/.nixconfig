#!/bin/sh

# hardware solution that avoids any of this nonsense:
# remove all disks other than nixos disk
# remove all other linux "boot manager" options from bios boot menu
# boot to the nixos disk, ensure it works
# add the other disks one by one back in and run nixos-rebuild

set -x

DEV=$1
SUFFIX=$2

beginswith() { case $2 in "$1"*) true;; *) false;; esac; }

if beginswith "/dev/nvme" "$DEV"; then
    DEVPREFIX="${DEV}p"
else
    DEVPREFIX="${DEV}"
fi

echo ${DEVPREFIX}

BOOTPGPTNAME="boot${SUFFIX}"
BOOTPLABEL="NIXBOOT${SUFFIX}"
ROOTPGPTNAME="root${SUFFIX}"
ROOTPLABEL="NIXROOT${SUFFIX}"

sudo zpool import -f ${ROOTPLABEL}
sudo zfs load-key ${ROOTPABEL}

sudo mount -t zfs ${ROOTPLABEL}/root /mnt

sudo mount ${DEVPREFIX}1 /mnt/boot
sudo mount -t zfs ${ROOTPLABEL}/home /mnt/home
sudo mount -t zfs ${ROOTPLABEL}/nix /mnt/nix

nixos-enter

NIXOS_INSTALL_BOOTLOADER=1 /nix/var/nix/profiles/system/bin/switch-to-configuration boot
