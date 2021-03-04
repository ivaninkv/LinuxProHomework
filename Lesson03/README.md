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