# ДЗ 4 по лекции "ZFS"

## Задание

Практические навыки работы с `ZFS`
Цель: Отрабатываем навыки работы с созданием томов `export`/`import` и установкой параметров.

* [Определить алгоритм с наилучшим сжатием](#compression)
* [Определить настройки pool’a](#pool)
* [Найти сообщение от преподавателей](#message)

Результат:
список команд которыми получен результат с их выводами

### Определить алгоритм с наилучшим сжатием

Зачем:
Отрабатываем навыки работы с созданием томов и установкой параметров. Находим наилучшее сжатие.

Шаги:
- определить какие алгоритмы сжатия поддерживает `zfs` (`gzip`/`gzip-N`, `zle`, `lzjb`, `lz4`)
- создать 4 файловых системы на каждой применить свой алгоритм сжатия
Для сжатия использовать либо текстовый файл либо группу файлов:
- скачать файл “Война и мир” и расположить на файловой системе `wget -O War_and_Peace.txt http://www.gutenberg.org/ebooks/2600.txt.utf-8`, либо скачать файл ядра распаковать и расположить на файловой системе

Результат:
- список команд которыми получен результат с их выводами
- вывод команды из которой видно какой из алгоритмов лучше

### Определить настройки pool’a

Зачем:
Для переноса дисков между системами используется функция `export`/`import`. Отрабатываем навыки работы с файловой системой `ZFS`

Шаги:
- Загрузить архив с файлами локально - https://drive.google.com/open?id=1KRBNW33QWqbvbVHa3hLJivOAt60yukkg. Распаковать.
- С помощью команды `zpool import` собрать pool `ZFS`.
- Командами `zfs` определить настройки
    - размер хранилища
    - тип pool
    - значение recordsize
    - какое сжатие используется
    - какая контрольная сумма используется\
Результат:
- список команд которыми восстановили `pool` . Желательно с Output команд.
- файл с описанием настроек `settings`

### Найти сообщение от преподавателей

Зачем:
для бэкапа используются технологии `snapshot`. `Snapshot` можно передавать между хостами и восстанавливать с помощью `send`/`receive`. Отрабатываем навыки восстановления `snapshot` и переноса файла.

Шаги:
- Скопировать файл из удаленной директории. https://drive.google.com/file/d/1gH8gCL9y7Nd5Ti3IRmplZPF1XjzxeRAG/view?usp=sharing
Файл был получен командой
`zfs send otus/storage@task2 > otus_task2.file`
- Восстановить файл локально. `zfs receive`
- Найти зашифрованное сообщение в файле `secret_message`

Результат:
- список шагов которыми восстанавливали
- зашифрованное сообщение


## Описание решения

В качестве стенда будем использовать `Vagrant`-стенд, расположенный по [адресу](https://github.com/nixuser/virtlab/tree/main/zfs).

### Определить алгоритм с наилучшим сжатием <a name="compression"></a>

Ниже приведены команды, с помощью которых можно создать пул, ФС и сравнить сжатие. Полный вывод, записанный утилитой `script` можно посмотреть [тут](step1.md).
```bash
sudo su
echo disk{1..6} | xargs -n 1 fallocate -l 500M
zpool create raid raidz3 $PWD/disk[1-6]
zpool list
man zfs | grep compression=
for i in gzip lz4 lzjb zle; do zfs create raid/$i; done
zfs create raid/gzipmax
for i in gzip lz4 lzjb zle; do zfs set compression=$i raid/$i; done
zfs set compression=gzip-9 raid/gzipmax
zfs get compression,compressratio
cp /vagrant/War_and_Peace.txt /raid/gzip
cp /vagrant/War_and_Peace.txt /raid/lz4
cp /vagrant/War_and_Peace.txt /raid/lzjb
cp /vagrant/War_and_Peace.txt /raid/zle
cp /vagrant/War_and_Peace.txt /raid/gzipmax
zfs get compression,compressratio
```
По получившимся результатам можно сделать вывод, что наилучшее сжатие текста обеспечивает алгоритм `gzip`.

### Определить настройки pool’a <a name="pool"></a>
Ниже приведены команды, которые позволяют скачть `pool`, импортировать его и узнать настройки. Полный вывод, записанный утилитой `script` можно посмотреть [тут](step2.md).
```bash
wget 'https://docs.google.com/uc?export=download&id=1KRBNW33QWqbvbVHa3hLJivOAt60yukkg' -O zfs_task1.tar.gz
tar -xvf zfs_task1.tar.gz
zpool import -d ${PWD}/zpoolexport/ otus
# смотрим настройки
zpool list -o name,size
zpool status otus
zfs get recordsize,compression,checksum otus
```
После выполнения команд, можно сделать вывод, что настройки пула следующие:
* размер хранилища - 480M
* тип pool - mirror-0
* значение recordsize - 128K
* какое сжатие используется - zle
* какая контрольная сумма используется - sha256


### Найти сообщение от преподавателей <a name="message"></a>
