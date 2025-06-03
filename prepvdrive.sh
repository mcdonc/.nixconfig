#!/bin/sh

set -ex

# "ef00" is "EFI System Partition", "-n 0:0:+2GiB" means 2 gig starting from the
# first available sector on rootdev "-c:0 boot" means give it a gpt name of boot
DEV=/dev/sdb
DEVPREFIX=$DEV
ROOTPGPTNAME="v"
ROOTPLABEL="v"

sgdisk --zap-all ${DEV}

sgdisk -n 0:0:0 -t 0:8300 -c 0:${ROOTPGPTNAME} ${DEV}

zpool create -f \
    -o ashift=12 \
    -o autotrim=on \
    -O compression=lz4 \
    -O acltype=posixacl \
    -O xattr=sa \
    -O relatime=on \
    -O normalization=formC \
    -O dnodesize=auto \
    -O mountpoint=none \
    ${ROOTPLABEL} \
    ${DEVPREFIX}1

zfs create -o mountpoint=/v ${ROOTPLABEL}/v
# reserved to cope with running out of disk space
zfs create -o refreservation=1G -o mountpoint=none ${ROOTPLABEL}/reserved
