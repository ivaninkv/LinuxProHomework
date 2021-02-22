# ДЗ 2 по лекции "Дисковая подсистема"

## Задание
Работа с mdadm
* [Добавить в Vagrantfile еще дисков](#vagrant)
* [Собрать R0/R5/R10 на выбор](#raid)
* [Прописать собранный рейд в конф, чтобы рейд собирался при загрузке](#config)
* [Сломать/починить raid](#fix)
* [Создать GPT раздел и 5 партиций](#gpt)

В качестве проверки принимаются - измененный `Vagrantfile`, скрипт для создания рейда, конф для автосборки рейда при загрузке.\
[ДЗ с *](#provision): доп. задание - `Vagrantfile`, который сразу собирает систему с подключенным рейдом\
ДЗ с ** перенести работающую систему с одним диском на RAID 1. Даунтайм на загрузку с нового диска предполагается. В качестве проверки принимается вывод команды `lsblk` до и после и описание хода решения (можно воспользоваться утилитой Script).\
Критерии оценки: Статус "Принято" ставится при выполнении следующего условия:
* Сдан `Vagrantfile` и скрипт для сборки, который можно запустить на поднятом образе

Доп. задание выполняется по желанию

## Описание решения

### Работа с `vagrant` <a name="vagrant"></a>

Для начала создадим директорию `disks` в домашнем каталоге:
```bash
mkdir ~/VMs_disks
```
Складывать диски будем отдельно, т.к. по умолчанию `vagrnat` копирует все содержимое каталога где лежит `Vagrantfile` на виртуальную машину в каталог `/vagrant`.\
Скачаем `Vagrantfile`, предложенный в качестве примера, по [ссылке](https://raw.githubusercontent.com/erlong15/otus-linux/master/Vagrantfile). В предложенном примере уже есть 4 диска, добавим еще парочку для практики. Обязательно меняем имя диска и номер порта. Также пропишем новые пути к дискам:
```rb
DISKS_PATH = ENV['HOME'] + '/VMs_disks'
...
:sata5 => {
    :dfile => DISKS_PATH + '/sata5.vdi',
    :size => 250, # Megabytes
    :port => 5
},
:sata6 => {
    :dfile => DISKS_PATH + '/sata6.vdi',
    :size => 250, # Megabytes
    :port => 6
}
```
Проверим наш `Vagrantfile`, поднимем виртуальную машину и подключимся к ней по `ssh`:
```bash
vagrant validate
vagrant up
vagrant ssh
```

### Создание RAID10 массива <a name="raid"></a>

Смотрим какие диски есть в системе одной из следующих команд:
```bash
lshw -short | grep disk
fdisk -l
lsblk
[root@otuslinux vagrant]# lsblk
NAME   MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
sda      8:0    0  250M  0 disk
sdb      8:16   0  250M  0 disk
sdc      8:32   0  250M  0 disk
sdd      8:48   0  250M  0 disk
sde      8:64   0  250M  0 disk
sdf      8:80   0  250M  0 disk
sdg      8:96   0   40G  0 disk
└─sdg1   8:97   0   40G  0 part /
```
В моем случае диски подготовленные для создания RAID - sd[a-f]. Занулим суперблоки и создадим RAID10:
```bash
mdadm --zero-superblock --force /dev/sd[a-f]
mdadm --create --verbose /dev/md0 -l 10 -n 6 /dev/sd[a-f]
# проверка на корректность создания RAID
cat /proc/mdstat
mdadm -D /dev/md0
Number   Major   Minor   RaidDevice State
    0       8        0        0      active sync set-A   /dev/sda
    1       8       16        1      active sync set-B   /dev/sdb
    2       8       32        2      active sync set-A   /dev/sdc
    3       8       48        3      active sync set-B   /dev/sdd
    4       8       64        4      active sync set-A   /dev/sde
    5       8       80        5      active sync set-B   /dev/sdf
```
Опция `-l` отвечает за уровень рейда, в нашем случае 10. Опция `-n` - количество дисков, в нашем случае 6.

### Создание конфига для RAID массива <a name="config"></a>

Система сама не запоминает какие RAID-массивы ей нужно создать и какие компоненты в них входят. Эта информация находится в файле `/etc/mdadm/mdadm.conf`.

Строки, которые следует добавить в этот файл, можно получить при помощи команды:
```bash
mdadm --detail --scan --verbose
```
Если файла ещё не существует, создадим его командами:
```bash
mkdir /etc/mdadm
echo "DEVICE partitions" > /etc/mdadm/mdadm.conf
mdadm --detail --scan --verbose | awk '/ARRAY/ {print}' >> /etc/mdadm/mdadm.conf
```
Подробнее можно почитать [тут](http://xgu.ru/wiki/mdadm#.D0.A1.D0.BE.D0.B7.D0.B4.D0.B0.D0.BD.D0.B8.D0.B5_.D0.BA.D0.BE.D0.BD.D1.84.D0.B8.D0.B3.D1.83.D1.80.D0.B0.D1.86.D0.B8.D0.BE.D0.BD.D0.BD.D0.BE.D0.B3.D0.BE_.D1.84.D0.B0.D0.B9.D0.BB.D0.B0_mdadm.conf)

### Ручная поломка и починка RAID <a name="fix"></a>

Диск в массиве можно условно сделать сбойным, ключ `--fail (-f)`. Пометим один из дисков как сбойный и посмотрим как это отразилось на массиве:
```bash
mdadm /dev/md0 --fail /dev/sdb
cat /proc/mdstat
Personalities : [raid10]
md0 : active raid10 sdf[5] sdd[3] sdc[2] sdb[1](F) sde[4] sda[0]
      761856 blocks super 1.2 512K chunks 2 near-copies [6/5] [U_UUUU]

unused devices: <none>
mdadm -D /dev/md0
Number   Major   Minor   RaidDevice State
    0       8        0        0      active sync set-A   /dev/sda
    -       0        0        1      removed
    2       8       32        2      active sync set-A   /dev/sdc
    3       8       48        3      active sync set-B   /dev/sdd
    4       8       64        4      active sync set-A   /dev/sde
    5       8       80        5      active sync set-B   /dev/sdf

    1       8       16        -      faulty   /dev/sdb
```
Удалим и заново добавим диск. Массив должен пересобраться:
```bash
mdadm /dev/md0 --remove /dev/sdb
mdadm /dev/md0 --add /dev/sdb
cat /proc/mdstat
Personalities : [raid10]
md0 : active raid10 sdb[6] sdf[5] sdd[3] sdc[2] sde[4] sda[0]
      761856 blocks super 1.2 512K chunks 2 near-copies [6/5] [U_UUUU]
      [=======>.............]  recovery = 37.2% (94848/253952) finish=0.0min speed=31616K/sec

unused devices: <none>
```
Больше деталей можно найти [тут](http://xgu.ru/wiki/mdadm#.D0.94.D0.B0.D0.BB.D1.8C.D0.BD.D0.B5.D0.B9.D1.88.D0.B0.D1.8F_.D1.80.D0.B0.D0.B1.D0.BE.D1.82.D0.B0_.D1.81_.D0.BC.D0.B0.D1.81.D1.81.D0.B8.D0.B2.D0.BE.D0.BC)

### Создание GPT раздела и 5 партиций на нем <a name="gpt"></a>

Создадим GPT раздел и 5 партиций на нем следующими командами:
```bash
# создание GPT раздела на RAID
parted -s /dev/md0 mklabel gpt
# создание 5 партиций
parted /dev/md0 mkpart primary ext4 0% 20%
parted /dev/md0 mkpart primary ext4 20% 40%
parted /dev/md0 mkpart primary ext4 40% 60%
parted /dev/md0 mkpart primary ext4 60% 80%
parted /dev/md0 mkpart primary ext4 80% 100%
# создание файловой системы на партициях
for i in $(seq 1 5); do sudo mkfs.ext4 /dev/md0p$i; done
# монтируем созданные партиции по каталогам
mkdir -p /raid/part{1,2,3,4,5}
for i in $(seq 1 5); do mount /dev/md0p$i /raid/part$i; done
# проверим созданные партиции
yum install -y tree
tree /raid
/raid
├── part1
│   └── lost+found
├── part2
│   └── lost+found
├── part3
│   └── lost+found
├── part4
│   └── lost+found
└── part5
    └── lost+found
```

### Задание со * - создание рейда при провижининге виртуальной машины <a name="provision"></a>

Чтобы не запускать создание RAID массива каждый раз при разворачивании машины, изменим `Vagrantfile` таким образом, чтобы массив собирался при деплое.\
Для этого в каталоге с `Vagrantfile` создадим скрипт `build_raid.sh` следующего содержания:
```bash
#! /bin/bash
set -e

mkdir -p ~root/.ssh
cp ~vagrant/.ssh/auth* ~root/.ssh
yum install -y mdadm smartmontools hdparm gdisk
echo "Soft installed!"

# смотрим диски, которые можно использовать для RAID
DISKS=`lsblk -slpdno NAME,TYPE | grep disk | awk '{printf $1" "}'`

mdadm --zero-superblock --force $DISKS
mdadm --create --verbose /dev/md0 -l 10 -n 6 $DISKS

mkdir /etc/mdadm
echo "DEVICE partitions" > /etc/mdadm/mdadm.conf
mdadm --detail --scan --verbose | awk '/ARRAY/ {print}' >> /etc/mdadm/mdadm.conf
```

И заменим провижининг в `Vagrantfile` на:
```rb
config.vm.provision "shell", path: "build_raid.sh"
```
