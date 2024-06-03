## Minimizing wear on SSDs

zpool set autotrim=on <pool-name>

## Expanding Space 

zpool set autotrim=on <pool-name>

## Adding/Replacing Drive in ZFS Pool

[Reference: ZFS on Linux - Changing a failed device](https://pve.proxmox.com/wiki/ZFS_on_Linux#sysadmin_zfs_change_failed_dev)

The commands do support maintaining the same partition layout as existing drives.

First check the status of the `proxmox-boot-tool`:

```bash
proxmox-boot-tool
```

Identify a healthy device that's in the existing ZFS pool (e.g. /dev/sdag).

Identify the device you would like to add (e.g. /dev/sdae).

First, we'll copy the partition table from the source disk (/dev/sdag)
to the destination disk (/dev/sdae):

```bash
sgdisk /dev/sdag -R /dev/sdae
```

Second, we'll randomize the GUIDs for the destination disk and its partitions:

```bash
sgdisk -G /dev/sdae
```

Now that we've got replicated partition tables on the new device, we need to get
the ZFS partition IDs for...
    a) the failed disk's and new disk's ZFS partition if we are replacing a failed drive,
    b) source and destination disks' ZFS partitions if we are simply attaching an additional drive.

```bash
ls -ahlp /dev/disk/by-id/
```

Third, if we are replacing a failed drive, then we will forcefully replace the
old partition with the new:

```bash
zpool replace -f rpool /dev/disk/by-id/ata-KINGSTON_SA400S37960G_50026B7784511148-part3 /dev/disk/by-id/ata-T-FORCE_1TB_TPBF2312040080104549-part3
```

Otherwise if we are just adding a disk, we can just attach the ZFS partition:

```bash
zpool attach rpool /dev/disk/by-id/ata-KINGSTON_SA400S37960G_50026B7784994958-part3 /dev/disk/by-id/ata-T-FORCE_1TB_TPBF2312040080104549-part3
```

Now we can check the status of the pool:

```bash
zpool status rpool
```

You should wait until resilvering has completed.

Take note if the proxmox-backup-tool says your disks are using grub - they most likely will.

Now we will format and initialize the ESP partition of the new disk which should be the #2 partition (if you 
are paranoid, they just check the partition labels).

```bash
proxmox-boot-tool format /dev/sdae2
proxmox-boot-tool init /dev/sdae2 grub
```