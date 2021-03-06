# ДЗ 3 по лекции "Файловые системы и LVM"

## Задание
Работа с LVM\
На имеющемся образе
```bash
/dev/mapper/VolGroup00-LogVol00 38G 738M 37G 2% /
```
* [Уменьшить том под `/` до 8G](#root)
* [Выделить том под `/var` в зеркало](#var)
* [Выделить том под `/home`](#home)
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
Возьмем `Vagrnatfile` по [ссылке](https://gitlab.com/otus_linux/stands-03-lvm.git) и пройдем пратику самостоятельно. Вывод, сохраненный с помощью утилиты `script`, можно посмотреть [здесь](practice.md).

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
Не выходя из `chroot`'а и не перезагружая сервер, создадим зеркало на дисках `/dev/sdc` и `/dev/sdb`
```bash
pvcreate /dev/sdc /dev/sdd
vgcreate vg_var /dev/sdc /dev/sdd
lvcreate -L 950M -m1 -n lv_var vg_var
```
Создадим на новом томе файловую систему и перемещаем туда каталог `/var`
```bash
mkfs.ext4 /dev/vg_var/lv_var
mount /dev/vg_var/lv_var /mnt/
cp -aR /var/* /mnt/
```
Сохраним содержимое старого `/var`
```bash
mkdir /tmp/oldvar && mv /var/* /tmp/oldvar
```
Смонтируем новый var в каталог `/var` и поправим `/etc/fstab` для автоматического монтирования
```bash
umount /mnt/
mount /dev/vg_var/lv_var /var
echo "`blkid | grep var: | awk '{print $2}'` /var ext4 defaults 0 0"  >> /etc/fstab
```
Перезагрузимся, проверим, что верно сделали предыдущие шаги и удалим временную `Volume Group`
```bash
lsblk
NAME                     MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
sda                        8:0    0   40G  0 disk
├─sda1                     8:1    0    1M  0 part
├─sda2                     8:2    0    1G  0 part /boot
└─sda3                     8:3    0   39G  0 part
  ├─VolGroup00-LogVol00  253:0    0    8G  0 lvm  /
  └─VolGroup00-LogVol01  253:1    0  1.5G  0 lvm  [SWAP]
sdb                        8:16   0   10G  0 disk
└─vg_root-lv_root        253:7    0   10G  0 lvm
sdc                        8:32   0    2G  0 disk
├─vg_var-lv_var_rmeta_0  253:2    0    4M  0 lvm
│ └─vg_var-lv_var        253:6    0  952M  0 lvm  /var
└─vg_var-lv_var_rimage_0 253:3    0  952M  0 lvm
  └─vg_var-lv_var        253:6    0  952M  0 lvm  /var
sdd                        8:48   0    1G  0 disk
├─vg_var-lv_var_rmeta_1  253:4    0    4M  0 lvm
│ └─vg_var-lv_var        253:6    0  952M  0 lvm  /var
└─vg_var-lv_var_rimage_1 253:5    0  952M  0 lvm
  └─vg_var-lv_var        253:6    0  952M  0 lvm  /var
sde                        8:64   0    1G  0 disk

lvremove /dev/vg_root/lv_root
vgremove /dev/vg_root
pvremove /dev/sdb
```

### Выделить том под `/home` <a name="home"></a>
Повторим шаги для каталога `/home`, которые мы делали для каталога `/var`. Создадим `Logical Volume`
```bash
lvcreate -n LogVol_Home -L 2G /dev/VolGroup00
```
Создадим файловую систему, примонтируем новый том и скопируем на него файлы
```bash
mkfs.xfs /dev/VolGroup00/LogVol_Home
mount /dev/VolGroup00/LogVol_Home /mnt/
cp -aR /home/* /mnt/
rm -rf /home/*
umount /mnt/
mount /dev/VolGroup00/LogVol_Home /home/
```
Поправим `/etc/fstab` для автоматического монтирования
```bash
echo "`blkid | grep Home: | awk '{print $2}'` /home xfs defaults 0 0"  >> /etc/fstab
```
Создадим несколько файлов в каталоге `/home`
```bash
touch /home/file{1..20}
```
Создаем снепшот
```bash
lvcreate -L 100MB -s -n home_snap /dev/VolGroup00/LogVol_Home
  Rounding up size to full physical extent 128.00 MiB
  Logical volume "home_snap" created.
```
Удалим часть файлов
```bash
rm -f /home/file{11..20}
ls /home/
file1  file10  file2  file3  file4  file5  file6  file7  file8  file9  vagrant
```
Восстановим снепшот и проверим, что все файлы на месте
```bash
umount /home/
lvconvert --merge /dev/VolGroup00/home_snap
  Merging of volume VolGroup00/home_snap started.
  VolGroup00/LogVol_Home: Merged: 100.00%
mount /home/
ls /home/
file1   file11  file13  file15  file17  file19  file20  file4  file6  file8  vagrant
file10  file12  file14  file16  file18  file2   file3   file5  file7  file9
```
