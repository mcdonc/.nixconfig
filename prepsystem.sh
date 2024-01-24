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

sgdisk --zap-all ${DEV}

# "ef00" is "EFI System Partition", "-n 0:0:+2GiB" means 2 gig starting from the
# first available sector on rootdev "-c:0 boot" means give it a gpt name of boot
sgdisk -n 0:0:+2GiB -t 0:ef00 -c 0:${BOOTPGPTNAME} ${DEV}

# 8300 is "Linux Filesystem", "-n 0:0:0" means take up the rest of the disk
# starting after the boot partition, "-c:0 root" means name it root
sgdisk -n 0:0:0 -t 0:8300 -c 0:${ROOTGPTNAME} ${DEV}

mkfs.fat -F 32 ${DEVPREFIX}1
fatlabel ${DEVPREFIX}1 ${BOOTPLABEL}

zpool create -f \
    -o altroot="/mnt" \
    -o ashift=12 \
    -o autotrim=on \
    -O compression=lz4 \
    -O acltype=posixacl \
    -O xattr=sa \
    -O relatime=on \
    -O normalization=formC \
    -O dnodesize=auto \
    -O encryption=aes-256-gcm \
    -O keylocation=prompt \
    -O keyformat=passphrase \
    -O mountpoint=none \
    ${ROOTPLABEL} \
    ${DEVPREFIX}2

zfs create -o mountpoint=legacy ${ROOTPLABEL}/root
zfs create -o mountpoint=legacy ${ROOTPLABEL}/home
zfs create -o mountpoint=legacy ${ROOTPLABEL}/nix

# reserved to cope with running out of disk space
zfs create -o refreservation=1G -o mountpoint=none ${ROOTPLABEL}/reserved

mount -t zfs ${ROOTPLABEL}/root /mnt
mkdir /mnt/boot
mkdir /mnt/home
mkdir /mnt/nix

mount ${DEVPREFIX}1 /mnt/boot
mount -t zfs ${ROOTPLABEL}/home /mnt/home
mount -t zfs ${ROOTPLABEL}/nix /mnt/nix

nixos-generate-config --root /mnt
