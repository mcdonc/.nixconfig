# keithmoon boots from a SATA SSD, not from the NVME root disk
# slot bifurcation of slot 3 is on in BIOS (x4x4)

#/ is mirror of nvme-eui.002538d63140d3a5-part2 & nvme-eui.002538d63140d3e2-part2
#/boot is VFBOOT (was ata-Samsung_SSD_850_EVO_1TB_S21CNXAG619917K-part1)

# spinning rust mirror 0
sudo zpool create -f \
    -O compression=lz4 \
    -O acltype=posixacl \
    -O xattr=sa \
    -O relatime=on \
    -O normalization=formC \
    -O dnodesize=auto \
    d \
    mirror \
    /dev/disk/by-id/scsi-35000cca05cdc2b2c \
    /dev/disk/by-id/scsi-35000cca05cdc2880

# mirror 1
sudo zpool add d mirror \
     /dev/disk/by-id/scsi-35000cca269b12c94  \
     /dev/disk/by-id/scsi-35000cca05cdd6924

# mirror 2
sudo zpool add d mirror \
     /dev/disk/by-id/scsi-35000cca03b9183c4 \
     /dev/disk/by-id/scsi-35000cca05cdbdd7c

# zfs permissions
sudo zfs allow -u chrism compression,create,mount,mountpoint,receive,destroy,diff,hold,load-key,refreservation,release,rename,rollback,send,snapshot d

# create a log on the EVO 870 500GB drives
sudo zpool add d log mirror \
     /dev/disk/by-id/ata-Samsung_SSD_870_EVO_500GB_S6PXNU0X200730K \
     /dev/disk/by-id/ata-Samsung_SSD_870_EVO_500GB_S6PXNU0X203974W

# remove the created log (or any other mirror)
sudo zpool remove d mirror-3

# create second partitions on EVO 850 disks (917K is alt boot disk)
sudo sgdisk -n 0:0:0 -t 0:8300 -c 0:log /dev/disk/by-id/ata-Samsung_SSD_850_EVO_1TB_S21CNXAG612853H-part2
sudo sgdisk -n 0:0:0 -t 0:8300 -c 0:log /dev/disk/by-id/ata-Samsung_SSD_850_EVO_1TB_S21CNXAG619917K-part2

# use them as a fast steam volume (steam doesnt like this)
sudo zpool create -f \
    -O compression=lz4 \
    -o ashift=12 \
    -o autotrim=on \
    -O acltype=posixacl \
    -O xattr=sa \
    -O relatime=on \
    -O normalization=formC \
    -O dnodesize=auto \
    s \
    mirror \
    /dev/disk/by-id/ata-Samsung_SSD_850_EVO_1TB_S21CNXAG612853H-part2 \
    /dev/disk/by-id/ata-Samsung_SSD_850_EVO_1TB_S21CNXAG619917K-part2

# or just use them individually as steam drives (current)
sudo mke2fs -t ext4 -L STEAM1 /dev/disk/by-id/ata-Samsung_SSD_850_EVO_1TB_S21CNXAG619917K-part2
sudo mke2fs -t ext4 -L STEAM2 /dev/disk/by-id/ata-Samsung_SSD_850_EVO_1TB_S21CNXAG612853H-part2

# create subvols on d
sudo zfs create -o encryption=aes-256-gcm -o keylocation=prompt \
     -o keyformat=passphrase -o mountpoint=/o d/o

# set mountpoint by hand
sudo zfs set mountpoint=/o d/o

# restore from existing dataset
sudo zfs send -cw b/storage@autosnap_2024-07-22_23:32:02_weekly | pv | zfs recv -u -s d/o

# create snapshot
sudo zfs snapshot b/storage@d-incremental

# inrcremental restore
sudo zfs send -cw -I b/storage@autosnap_2024-07-22_23:32:02_weekly b/storage@d-incremental | pv | zfs recv -u d/o

# disable file indexing
balooctl6 suspend
balooctl6 disable

# suspected bad (thrown away):
# /dev/disk/by-id/scsi-35000cca25c1e8f94

# remaining good:
# /dev/disk/by-id/scsi-35000cca05cdbdd7c

# generate a 32-byte hex key
# openssl rand -hex 32

# boot.initrd.secrets."/key.txt" = /path/to/key.txt
# keylocation=file:///key.txt
