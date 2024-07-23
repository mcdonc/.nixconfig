# keithmoon boots from a SATA SSD, not from the NVME root disk
# slot bifurcation of slot 3 is on in BIOS (x4x4)
/ is mirror of nvme-eui.002538d63140d3a5-part2 & nvme-eui.002538d63140d3e2-part2
/boot is ata-Samsung_SSD_850_EVO_1TB_S21CNXAG619917K-part1

# spinning rust
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

sudo zpool add d mirror \
     /dev/disk/by-id/scsi-35000cca05cdbdd7c \
     /dev/disk/by-id/scsi-35000cca25c1e8f94

sudo zpool add d mirror \
     /dev/disk/by-id/scsi-35000cca269b12c94  \
     /dev/disk/by-id/scsi-35000cca05cdd6924

# create second partitions on EVO 850 log disks (one is boot disk)
sudo sgdisk -n 0:0:0 -t 0:8300 -c 0:log /dev/disk/by-id/ata-Samsung_SSD_850_EVO_1TB_S21CNXAG612853H-part2
sudo sgdisk -n 0:0:0 -t 0:8300 -c 0:log /dev/disk/by-id/ata-Samsung_SSD_850_EVO_1TB_S21CNXAG619917K-part2

# create a log on the EVO 850 second partitions
sudo zpool add d log mirror \
     /dev/disk/by-id/ata-Samsung_SSD_850_EVO_1TB_S21CNXAG612853H-part2 \
     /dev/disk/by-id/ata-Samsung_SSD_850_EVO_1TB_S21CNXAG619917K-part2

# create subvols on d
sudo zfs create -o encryption=aes-256-gcm -o keylocation=prompt \
     -o keyformat=passphrase d/enc
