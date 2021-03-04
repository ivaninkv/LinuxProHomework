# ДЗ 3 по лекции "Файловые системы и LVM"

## Задание
Работа с LVM\
На имеющемся образе
```bash
/dev/mapper/VolGroup00-LogVol00 38G 738M 37G 2% /
```
* [Уменьшить том под `/` до 8G](#root)
* [Выделить том под `/var` в зеркало](#var)
* [Выделить том под `/home`]
* `/var` - сделать в mirror
* `/home` - сделать том для снэпшотов
* прописать монтирование в `fstab`
* попробовать с разными опциями и разными файловыми системами (на выбор)
    * сгенерить файлы в `/home`
    * снять снэпшот
    * удалить часть файлов
    * восстановиться со снэпшота
    * залогировать работу можно с помощью утилиты `script`

ДЗ со * -  на нашей куче дисков попробовать поставить `btrfs`/`zfs` - с кешем, снэпшотами - разметить здесь каталог `/opt`.\
Критерии оценки: Статус "Принято" ставится при выполнении основной части.\
Задание со звездочкой выполняется по желанию.

## Описание решения
### Самостоятельная практика
Возьмем `Vagrnatfile` по [ссылке](https://gitlab.com/otus_linux/stands-03-lvm.git) и пройдем пратику самостоятельно. Ниже вывод, сохраненный с помощью утилиты `script`:
```
Script started on Sun 28 Feb 2021 05:39:02 PM UTC
[root@lvm vagrant]# lsblk
NAME                    MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
sda                       8:0    0   40G  0 disk
├─sda1                    8:1    0    1M  0 part
├─sda2                    8:2    0    1G  0 part /boot
└─sda3                    8:3    0   39G  0 part
  ├─VolGroup00-LogVol00 253:0    0 37.5G  0 lvm  /
  └─VolGroup00-LogVol01 253:1    0  1.5G  0 lvm  [SWAP]
sdb                       8:16   0   10G  0 disk
sdc                       8:32   0    2G  0 disk
sdd                       8:48   0    1G  0 disk
sde                       8:64   0    1G  0 disk
[root@lvm vagrant]# lvmdiskscan
  /dev/VolGroup00/LogVol00 [     <37.47 GiB]
  /dev/VolGroup00/LogVol01 [       1.50 GiB]
  /dev/sda2                [       1.00 GiB]
  /dev/sda3                [     <39.00 GiB] LVM physical volume
  /dev/sdb                 [      10.00 GiB]
  /dev/sdc                 [       2.00 GiB]
  /dev/sdd                 [       1.00 GiB]
  /dev/sde                 [       1.00 GiB]
  4 disks
  3 partitions
  0 LVM physical volume whole disks
  1 LVM physical volume
[root@lvm vagrant]# pvcreate /dev/sdb
  Physical volume "/dev/sdb" successfully created.
[root@lvm vagrant]# vgcreate otus /dev/sdb
  Volume group "otus" successfully created
[root@lvm vagrant]# lvcreate -l+80%FREE -n test otus
  Logical volume "test" created.
[root@lvm vagrant]# vgdisplay otus
  --- Volume group ---
  VG Name               otus
  System ID
  Format                lvm2
  Metadata Areas        1
  Metadata Sequence No  2
  VG Access             read/write
  VG Status             resizable
  MAX LV                0
  Cur LV                1
  Open LV               0
  Max PV                0
  Cur PV                1
  Act PV                1
  VG Size               <10.00 GiB
  PE Size               4.00 MiB
  Total PE              2559
  Alloc PE / Size       2047 / <8.00 GiB
  Free  PE / Size       512 / 2.00 GiB
  VG UUID               E4xTNX-zBtc-2ton-fw7d-fLXW-tDbS-lJ1eBT

[root@lvm vagrant]# vgdisplay -v otus | grep 'PV Name'
  PV Name               /dev/sdb
[root@lvm vagrant]# lvdisplay /dev/otus/test
  --- Logical volume ---
  LV Path                /dev/otus/test
  LV Name                test
  VG Name                otus
  LV UUID                uHGDYa-Gbff-imxv-hDf6-k82o-7cgg-quxHRY
  LV Write Access        read/write
  LV Creation host, time lvm, 2021-02-28 17:41:27 +0000
  LV Status              available
  # open                 0
  LV Size                <8.00 GiB
  Current LE             2047
  Segments               1
  Allocation             inherit
  Read ahead sectors     auto
  - currently set to     8192
  Block device           253:2

[root@lvm vagrant]# vgs
  VG         #PV #LV #SN Attr   VSize   VFree
  VolGroup00   1   2   0 wz--n- <38.97g    0
  otus         1   1   0 wz--n- <10.00g 2.00g
[root@lvm vagrant]# lvs
  LV       VG         Attr       LSize   Pool Origin Data%  Meta%  Move Log Cpy%Sync Convert
  LogVol00 VolGroup00 -wi-ao---- <37.47g
  LogVol01 VolGroup00 -wi-ao----   1.50g
  test     otus       -wi-a-----  <8.00g
[root@lvm vagrant]# pvs
  PV         VG         Fmt  Attr PSize   PFree
  /dev/sda3  VolGroup00 lvm2 a--  <38.97g    0
  /dev/sdb   otus       lvm2 a--  <10.00g 2.00g
[root@lvm vagrant]# lvcreate -L100M -n small otus
  Logical volume "small" created.
[root@lvm vagrant]# lvs
  LV       VG         Attr       LSize   Pool Origin Data%  Meta%  Move Log Cpy%Sync Convert
  LogVol00 VolGroup00 -wi-ao---- <37.47g
  LogVol01 VolGroup00 -wi-ao----   1.50g
  small    otus       -wi-a----- 100.00m
  test     otus       -wi-a-----  <8.00g
[root@lvm vagrant]# mkfs
mkfs         mkfs.btrfs   mkfs.cramfs  mkfs.ext2    mkfs.ext3    mkfs.ext4    mkfs.minix   mkfs.xfs
[root@lvm vagrant]# mkfs.ext4 /dev/otus/test
mke2fs 1.42.9 (28-Dec-2013)
Filesystem label=
OS type: Linux
Block size=4096 (log=2)
Fragment size=4096 (log=2)
Stride=0 blocks, Stripe width=0 blocks
524288 inodes, 2096128 blocks
104806 blocks (5.00%) reserved for the super user
First data block=0
Maximum filesystem blocks=2147483648
64 block groups
32768 blocks per group, 32768 fragments per group
8192 inodes per group
Superblock backups stored on blocks:
        32768, 98304, 163840, 229376, 294912, 819200, 884736, 1605632

Allocating group tables: done
Writing inode tables: done
Creating journal (32768 blocks): done
Writing superblocks and filesystem accounting information: done

[root@lvm vagrant]# mkdir /data
[root@lvm vagrant]# mount /dev/otus/test /data/
[root@lvm vagrant]# mount | grep /data
/dev/mapper/otus-test on /data type ext4 (rw,relatime,seclabel,data=ordered)
[root@lvm vagrant]# pvcreate /dev/sdc
  Physical volume "/dev/sdc" successfully created.
[root@lvm vagrant]# vgextend otus /dev/sdc
  Volume group "otus" successfully extended
[root@lvm vagrant]# vgdisplay -v otus | grep 'PV Name'
  PV Name               /dev/sdb
  PV Name               /dev/sdc
[root@lvm vagrant]# vgs
  VG         #PV #LV #SN Attr   VSize   VFree
  VolGroup00   1   2   0 wz--n- <38.97g     0
  otus         2   2   0 wz--n-  11.99g <3.90g
[root@lvm vagrant]# dd if=/dev/zero of=/data/test.log bs=1M count=8000 status=progress
8249147392 bytes (8.2 GB) copied, 63.630489 s, 130 MB/s
dd: error writing ‘/data/test.log’: No space left on device
7880+0 records in
7879+0 records out
8262189056 bytes (8.3 GB) copied, 63.7809 s, 130 MB/s
[root@lvm vagrant]# df -Th /data/
Filesystem            Type  Size  Used Avail Use% Mounted on
/dev/mapper/otus-test ext4  7.8G  7.8G     0 100% /data
[root@lvm vagrant]# lvextend -l+80%FREE /dev/otus/test
  Size of logical volume otus/test changed from <8.00 GiB (2047 extents) to <11.12 GiB (2846 extents).
  Logical volume otus/test successfully resized.
[root@lvm vagrant]# lvs /dev/otus/test
  LV   VG   Attr       LSize   Pool Origin Data%  Meta%  Move Log Cpy%Sync Convert
  test otus -wi-ao---- <11.12g
[root@lvm vagrant]# df -Th /data/
Filesystem            Type  Size  Used Avail Use% Mounted on
/dev/mapper/otus-test ext4  7.8G  7.8G     0 100% /data
[root@lvm vagrant]# resize2fs /dev/otus/
small  test
[root@lvm vagrant]# resize2fs /dev/otus/test
resize2fs 1.42.9 (28-Dec-2013)
Filesystem at /dev/otus/test is mounted on /data; on-line resizing required
old_desc_blocks = 1, new_desc_blocks = 2
The filesystem on /dev/otus/test is now 2914304 blocks long.

[root@lvm vagrant]# df -Th /data/
Filesystem            Type  Size  Used Avail Use% Mounted on
/dev/mapper/otus-test ext4   11G  7.8G  2.6G  76% /data
[root@lvm vagrant]# umount /data/
[root@lvm vagrant]# e2fsck -fy /dev/otus/test
e2fsck 1.42.9 (28-Dec-2013)
Pass 1: Checking inodes, blocks, and sizes
Pass 2: Checking directory structure
Pass 3: Checking directory connectivity
Pass 4: Checking reference counts
Pass 5: Checking group summary information
/dev/otus/test: 12/729088 files (0.0% non-contiguous), 2105907/2914304 blocks
[root@lvm vagrant]# resize2fs /dev/otus/test 10G
resize2fs 1.42.9 (28-Dec-2013)
Resizing the filesystem on /dev/otus/test to 2621440 (4k) blocks.
The filesystem on /dev/otus/test is now 2621440 blocks long.

[root@lvm vagrant]# lvreduce /dev/otus/test -L 10G
  WARNING: Reducing active logical volume to 10.00 GiB.
  THIS MAY DESTROY YOUR DATA (filesystem etc.)
Do you really want to reduce otus/test? [y/n]: y
  Size of logical volume otus/test changed from <11.12 GiB (2846 extents) to 10.00 GiB (2560 extents).
  Logical volume otus/test successfully resized.
[root@lvm vagrant]# mount /dev/otus/test /data/
[root@lvm vagrant]# df -Th /data/
Filesystem            Type  Size  Used Avail Use% Mounted on
/dev/mapper/otus-test ext4  9.8G  7.8G  1.6G  84% /data
[root@lvm vagrant]# lvs /dev/otus/test
  LV   VG   Attr       LSize  Pool Origin Data%  Meta%  Move Log Cpy%Sync Convert
  test otus -wi-ao---- 10.00g
[root@lvm vagrant]# lvcreate -L 500M -s -n test-snap /dev/otus/test
  Logical volume "test-snap" created.
[root@lvm vagrant]# vgs
  VG         #PV #LV #SN Attr   VSize   VFree
  VolGroup00   1   2   0 wz--n- <38.97g     0
  otus         2   3   1 wz--n-  11.99g <1.41g
[root@lvm vagrant]# vgs -o +lv_size,lv_name | grep test
  otus         2   3   1 wz--n-  11.99g <1.41g  10.00g test
  otus         2   3   1 wz--n-  11.99g <1.41g 500.00m test-snap
[root@lvm vagrant]# lsblk
NAME                    MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
sda                       8:0    0   40G  0 disk
├─sda1                    8:1    0    1M  0 part
├─sda2                    8:2    0    1G  0 part /boot
└─sda3                    8:3    0   39G  0 part
  ├─VolGroup00-LogVol00 253:0    0 37.5G  0 lvm  /
  └─VolGroup00-LogVol01 253:1    0  1.5G  0 lvm  [SWAP]
sdb                       8:16   0   10G  0 disk
├─otus-small            253:3    0  100M  0 lvm
└─otus-test-real        253:4    0   10G  0 lvm
  ├─otus-test           253:2    0   10G  0 lvm  /data
  └─otus-test--snap     253:6    0   10G  0 lvm
sdc                       8:32   0    2G  0 disk
├─otus-test-real        253:4    0   10G  0 lvm
│ ├─otus-test           253:2    0   10G  0 lvm  /data
│ └─otus-test--snap     253:6    0   10G  0 lvm
└─otus-test--snap-cow   253:5    0  500M  0 lvm
  └─otus-test--snap     253:6    0   10G  0 lvm
sdd                       8:48   0    1G  0 disk
sde                       8:64   0    1G  0 disk
[root@lvm vagrant]# mkdir /data-snap
[root@lvm vagrant]# mount /dev/otus/test-snap /data-snap/
[root@lvm vagrant]# ll /data-snap/
total 8068564
drwx------. 2 root root      16384 Feb 28 17:44 lost+found
-rw-r--r--. 1 root root 8262189056 Feb 28 17:48 test.log
[root@lvm vagrant]# umount /data-snap/
[root@lvm vagrant]# rm /data/test.log
rm: remove regular file ‘/data/test.log’? y
[root@lvm vagrant]# ll /data
total 16
drwx------. 2 root root 16384 Feb 28 17:44 lost+found
[root@lvm vagrant]# umount /data
[root@lvm vagrant]# lvconvert --merge /dev/otus/test-snap
  Merging of volume otus/test-snap started.
  otus/test: Merged: 100.00%
[root@lvm vagrant]# mount /dev/otus/test /data
[root@lvm vagrant]# ll /data
total 8068564
drwx------. 2 root root      16384 Feb 28 17:44 lost+found
-rw-r--r--. 1 root root 8262189056 Feb 28 17:48 test.log
[root@lvm vagrant]# pvcreate /dev/sd{d,e}
  Physical volume "/dev/sdd" successfully created.
  Physical volume "/dev/sde" successfully created.
[root@lvm vagrant]# vgcreate vg0 /dev/sd{d,e}
  Volume group "vg0" successfully created
[root@lvm vagrant]# lvcreate -l+80%FREE -m1 -n mirror vg0
  Logical volume "mirror" created.
[root@lvm vagrant]# lvs
  LV       VG         Attr       LSize   Pool Origin Data%  Meta%  Move Log Cpy%Sync Convert
  LogVol00 VolGroup00 -wi-ao---- <37.47g
  LogVol01 VolGroup00 -wi-ao----   1.50g
  small    otus       -wi-a----- 100.00m
  test     otus       -wi-ao----  10.00g
  mirror   vg0        rwi-a-r--- 816.00m                                    61.28
[root@lvm vagrant]# lvs
  LV       VG         Attr       LSize   Pool Origin Data%  Meta%  Move Log Cpy%Sync Convert
  LogVol00 VolGroup00 -wi-ao---- <37.47g
  LogVol01 VolGroup00 -wi-ao----   1.50g
  small    otus       -wi-a----- 100.00m
  test     otus       -wi-ao----  10.00g
  mirror   vg0        rwi-a-r--- 816.00m                                    100.00
[root@lvm vagrant]# lsblk
NAME                    MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
sda                       8:0    0   40G  0 disk
├─sda1                    8:1    0    1M  0 part
├─sda2                    8:2    0    1G  0 part /boot
└─sda3                    8:3    0   39G  0 part
  ├─VolGroup00-LogVol00 253:0    0 37.5G  0 lvm  /
  └─VolGroup00-LogVol01 253:1    0  1.5G  0 lvm  [SWAP]
sdb                       8:16   0   10G  0 disk
├─otus-test             253:2    0   10G  0 lvm  /data
└─otus-small            253:3    0  100M  0 lvm
sdc                       8:32   0    2G  0 disk
└─otus-test             253:2    0   10G  0 lvm  /data
sdd                       8:48   0    1G  0 disk
├─vg0-mirror_rmeta_0    253:4    0    4M  0 lvm
│ └─vg0-mirror          253:8    0  816M  0 lvm
└─vg0-mirror_rimage_0   253:5    0  816M  0 lvm
  └─vg0-mirror          253:8    0  816M  0 lvm
sde                       8:64   0    1G  0 disk
├─vg0-mirror_rmeta_1    253:6    0    4M  0 lvm
│ └─vg0-mirror          253:8    0  816M  0 lvm
└─vg0-mirror_rimage_1   253:7    0  816M  0 lvm
  └─vg0-mirror          253:8    0  816M  0 lvm
[root@lvm vagrant]# exit

Script done on Sun 28 Feb 2021 06:06:01 PM UTC
```

### Уменьшить том под / до 8G <a name="root"></a>
Для начала удалим `logical volume`, `volume group` и `physical volume`, созданные на самостоятельной практике:
```bash
# удаляем volume group
lvscan
ACTIVE            '/dev/VolGroup00/LogVol00' [<37.47 GiB] inherit
ACTIVE            '/dev/VolGroup00/LogVol01' [1.50 GiB] inherit
ACTIVE            '/dev/vg0/mirror' [816.00 MiB] inherit
ACTIVE            '/dev/otus/test' [10.00 GiB] inherit
ACTIVE            '/dev/otus/small' [100.00 MiB] inherit
lvremove /dev/otus/test
lvremove /dev/otus/small
lvremove /dev/vg0/mirror
# удаляем volume group
vgs
VG         #PV #LV #SN Attr   VSize   VFree
VolGroup00   1   2   0 wz--n- <38.97g     0
otus         2   0   0 wz--n-  11.99g 11.99g
vg0          2   0   0 wz--n-   1.99g  1.99g
vgremove otus
vgremove vg0
# удаляем physical volume
pvs
PV         VG         Fmt  Attr PSize   PFree
/dev/sda3  VolGroup00 lvm2 a--  <38.97g     0
/dev/sdb              lvm2 ---   10.00g 10.00g
/dev/sdc              lvm2 ---    2.00g  2.00g
/dev/sdd              lvm2 ---    1.00g  1.00g
/dev/sde              lvm2 ---    1.00g  1.00g
pvremove /dev/sdb
pvremove /dev/sdc
pvremove /dev/sdd
pvremove /dev/sde
```
Установим пакет `xfsdump`  для снятия копии тома:
```bash
yum install -y xfsdump
```
Подготовим временный том для корневого раздела, изменим загрузчик и загрузимся с другого тома. Затем пересоздадим оригинальный `logical volume` с меньшим размером и вернем все обратно:
```bash
# создаем объекты lvm, файловую систему и делаем дамп данных текущего корневого раздела
pvcreate /dev/sdb
vgcreate vg_root /dev/sdb
lvcreate -n lv_root -l +100%FREE /dev/vg_root
mkfs.xfs /dev/vg_root/lv_root
mount /dev/vg_root/lv_root /mnt
xfsdump -J - /dev/VolGroup00/LogVol00 | xfsrestore -J - /mnt

# обновляем конфигурацию grub2 и initrd
for i in /proc/ /sys/ /dev/ /run/ /boot/; do mount --bind $i /mnt/$i; done
chroot /mnt/
grub2-mkconfig -o /boot/grub2/grub.cfg
cd /boot/; for i in `ls initramfs-*img`; do dracut -v $i `echo $i | sed "s/initramfs-//g;s/.img//g"` --force; done

# заменить rd.lvm.lv=VolGroup00/LogVol00 на rd.lvm.lv=vg_root/lv_root
vi /boot/grub2/grub.cfg

# перезагружаем машину и продолжаем работу
# пересоздаем том
lvremove /dev/VolGroup00/LogVol00
lvcreate -n /dev/VolGroup00/LogVol00 -L 8G /dev/VolGroup00

# создаем ФС, монтируем том и делаем дамп
mkfs.xfs /dev/VolGroup00/LogVol00
mount /dev/VolGroup00/LogVol00 /mnt
xfsdump -J - /dev/vg_root/lv_root | xfsrestore -J - /mnt/

# обновляем конфигурацию grub2 и initrd
for i in /proc/ /sys/ /dev/ /run/ /boot/; do mount --bind $i /mnt/$i; done
chroot /mnt/
grub2-mkconfig -o /boot/grub2/grub.cfg
cd /boot/; for i in `ls initramfs-*img`; do dracut -v $i `echo $i | sed "s/initramfs-//g;s/.img//g"` --force; done
```

### Выделить том под `/var` в зеркало <a name="var"></a>