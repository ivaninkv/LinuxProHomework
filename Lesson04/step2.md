# Определить настройки pool’a

Полный вывод, записанный с помощью утилиты `script`:
```
Script started on 2021-03-07 10:00:58+00:00
[vagrant@server ~]$ sudo su
[root@server vagrant]# wget 'https://docs.google.com/uc?export=download&id=1KRBNW33QWqbvbVHa3hLJivOAt60yukkg' -O zfs_task1.tar.gz
--2021-03-07 10:01:19--  https://docs.google.com/uc?export=download&id=1KRBNW33QWqbvbVHa3hLJivOAt60yukkg
Resolving docs.google.com (docs.google.com)... 64.233.165.194
Connecting to docs.google.com (docs.google.com)|64.233.165.194|:443... connected.
HTTP request sent, awaiting response... 302 Moved Temporarily
Location: https://doc-0c-bo-docs.googleusercontent.com/docs/securesc/ha0ro937gcuc7l7deffksulhg5h7mbp1/p5jr5khtjal22ccd4ntne169j1o53p9s/1615113225000/16189157874053420687/*/1KRBNW33QWqbvbVHa3hLJivOAt60yukkg?e=download [following]
Warning: wildcards not supported in HTTP.
--2021-03-07 10:01:24--  https://doc-0c-bo-docs.googleusercontent.com/docs/securesc/ha0ro937gcuc7l7deffksulhg5h7mbp1/p5jr5khtjal22ccd4ntne169j1o53p9s/1615113225000/16189157874053420687/*/1KRBNW33QWqbvbVHa3hLJivOAt60yukkg?e=download
Resolving doc-0c-bo-docs.googleusercontent.com (doc-0c-bo-docs.googleusercontent.com)... 64.233.164.132
Connecting to doc-0c-bo-docs.googleusercontent.com (doc-0c-bo-docs.googleusercontent.com)|64.233.164.132|:443... connected.
HTTP request sent, awaiting response... 200 OK
Length: unspecified [application/x-gzip]
Saving to: ‘zfs_task1.tar.gz’

zfs_task1.tar.gz                      [      <=>                                                  ]   6.94M  6.45MB/s    in 1.1s

2021-03-07 10:01:26 (6.45 MB/s) - ‘zfs_task1.tar.gz’ saved [7275140]

[root@server vagrant]# tar -xvf zfs_task1.tar.gz
zpoolexport/
zpoolexport/filea
zpoolexport/fileb
[root@server vagrant]# zpool import -d ${PWD}/zpoolexport/ otus
[root@server vagrant]# zpool list -o name,size
NAME   SIZE
otus   480M
raid  2.75G
[root@server vagrant]# zpool status otus
  pool: otus
 state: ONLINE
  scan: none requested
config:

        NAME                                 STATE     READ WRITE CKSUM
        otus                                 ONLINE       0     0     0
          mirror-0                           ONLINE       0     0     0
            /home/vagrant/zpoolexport/filea  ONLINE       0     0     0
            /home/vagrant/zpoolexport/fileb  ONLINE       0     0     0

errors: No known data errors
[root@server vagrant]# zfs get recordsize,compression,checksum otus
NAME  PROPERTY     VALUE      SOURCE
otus  recordsize   128K       local
otus  compression  zle        local
otus  checksum     sha256     local
[root@server vagrant]# exit
[vagrant@server ~]$ exit

Script done on 2021-03-07 10:03:03+00:00
```
