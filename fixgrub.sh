#!/bin/sh

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

mount -t zfs ${ROOTPLABEL}/root /mnt
mkdir /mnt/boot
mkdir /mnt/home
mkdir /mnt/nix

mount ${DEVPREFIX}1 /mnt/boot
mount -t zfs ${ROOTPLABEL}/home /mnt/home
mount -t zfs ${ROOTPLABEL}/nix /mnt/nix

#nixos-generate-config --root /mnt
