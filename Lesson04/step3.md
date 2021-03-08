# Найти сообщение от преподавателей

Полный вывод, записанный с помощью утилиты `script`:
```
Script started on 2021-03-07 10:43:27+00:00
[vagrant@server ~]$ sudo su
[root@server vagrant]# wget 'https://docs.google.com/uc?export=download&id=1gH8gCL9y7Nd5Ti3IRmplZPF1XjzxeRAG' -O otus_task2.file
--2021-03-07 10:43:43--  https://docs.google.com/uc?export=download&id=1gH8gCL9y7Nd5Ti3IRmplZPF1XjzxeRAG
Resolving docs.google.com (docs.google.com)... 64.233.164.194
Connecting to docs.google.com (docs.google.com)|64.233.164.194|:443... connected.
HTTP request sent, awaiting response... 302 Moved Temporarily
Location: https://doc-00-bo-docs.googleusercontent.com/docs/securesc/ha0ro937gcuc7l7deffksulhg5h7mbp1/gf64g9o3nbn28r92jniht4i25godu4mu/1615115550000/16189157874053420687/*/1gH8gCL9y7Nd5Ti3IRmplZPF1XjzxeRAG?e=download [following]
Warning: wildcards not supported in HTTP.
--2021-03-07 10:43:44--  https://doc-00-bo-docs.googleusercontent.com/docs/securesc/ha0ro937gcuc7l7deffksulhg5h7mbp1/gf64g9o3nbn28r92jniht4i25godu4mu/1615115550000/16189157874053420687/*/1gH8gCL9y7Nd5Ti3IRmplZPF1XjzxeRAG?e=download
Resolving doc-00-bo-docs.googleusercontent.com (doc-00-bo-docs.googleusercontent.com)... 173.194.221.132
Connecting to doc-00-bo-docs.googleusercontent.com (doc-00-bo-docs.googleusercontent.com)|173.194.221.132|:443... connected.
HTTP request sent, awaiting response... 200 OK
Length: unspecified [application/octet-stream]
Saving to: ‘otus_task2.file’

otus_task2.file                       [     <=>                                                   ]   5.18M  5.05MB/s    in 1.0s

2021-03-07 10:43:46 (5.05 MB/s) - ‘otus_task2.file’ saved [5432736]

[root@server vagrant]# zfs receive raid/otus < otus_task2.file
[root@server vagrant]# find /raid/otus/ -name "secret_message" -exec cat {} \;
https://github.com/sindresorhus/awesome
[root@server vagrant]# exit
[vagrant@server ~]$ exit

Script done on 2021-03-07 10:44:10+00:00
```
