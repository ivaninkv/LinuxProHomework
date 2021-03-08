# Определить алгоритм с наилучшим сжатием

Полный вывод, записанный с помощью утилиты `script`:
```
Script started on 2021-03-07 08:40:35+00:00
[vagrant@server ~]$ sudo su
[root@server vagrant]# echo disk{1..6} | xargs -n 1 fallocate -l 500M
[root@server vagrant]# zpool create raid raidz3 $PWD/disk[1-6]
[root@server vagrant]# zpool list
NAME   SIZE  ALLOC   FREE  CKPOINT  EXPANDSZ   FRAG    CAP  DEDUP    HEALTH  ALTROOT
raid  2.75G   300K  2.75G        -         -     0%     0%  1.00x    ONLINE  -
[root@server vagrant]# man zfs | grep compression=
     compression=on, as a less resource-intensive alternative.
                           refcompressratio property.  Compression can be turned on by running: zfs set compression=on dataset.
     compression=on|off|gzip|gzip-N|lz4|lzjb|zle
       # zfs set compression=off pool/home
       # zfs set compression=on pool/home/anne
[root@server vagrant]# for i in gzip lz4 lzjb zle; do zfs create raid/$i; done
[root@server vagrant]# zfs create raid/gzipmax
[root@server vagrant]# for i in gzip lz4 lzjb zle; do zfs set compression=$i raid/$i; done
[root@server vagrant]# zfs set compression=gzip9 raid/gzipmax
cannot set property for 'raid/gzipmax': 'compression' must be one of 'on | off | lzjb | gzip | gzip-[1-9] | zle | lz4'
[root@server vagrant]# zfs set compression=gzip-9 raid/gzipmax
[root@server vagrant]# zfs get compression,compressratio
NAME          PROPERTY       VALUE     SOURCE
raid          compression    off       default
raid          compressratio  1.00x     -
raid/gzip     compression    gzip      local
raid/gzip     compressratio  1.00x     -
raid/gzipmax  compression    gzip-9    local
raid/gzipmax  compressratio  1.00x     -
raid/lz4      compression    lz4       local
raid/lz4      compressratio  1.00x     -
raid/lzjb     compression    lzjb      local
raid/lzjb     compressratio  1.00x     -
raid/zle      compression    zle       local
raid/zle      compressratio  1.00x     -
[root@server vagrant]# cp /vagrant/War_and_Peace.txt raid/gzip
cp: cannot create regular file 'raid/gzip': No such file or directory
[root@server vagrant]# cp /vagrant/War_and_Peace.txt /raid/gzip
[root@server vagrant]# cp /vagrant/War_and_Peace.txt /raid/lz4
[root@server vagrant]# cp /vagrant/War_and_Peace.txt /raid/lzjb
[root@server vagrant]# cp /vagrant/War_and_Peace.txt /raid/zle
[root@server vagrant]# cp /vagrant/War_and_Peace.txt /raid/gzipmax
[root@server vagrant]# zfs get compression,compressratio
NAME          PROPERTY       VALUE     SOURCE
raid          compression    off       default
raid          compressratio  1.64x     -
raid/gzip     compression    gzip      local
raid/gzip     compressratio  2.69x     -
raid/gzipmax  compression    gzip-9    local
raid/gzipmax  compressratio  2.70x     -
raid/lz4      compression    lz4       local
raid/lz4      compressratio  1.64x     -
raid/lzjb     compression    lzjb      local
raid/lzjb     compressratio  1.37x     -
raid/zle      compression    zle       local
raid/zle      compressratio  1.03x     -
[root@server vagrant]# exit
[vagrant@server ~]$ exit

Script done on 2021-03-07 08:44:35+00:00
```