# ДЗ 1 по лекции "С чего начинается Linux"

## Задание
Обновить ядро в базовой системе

Цель: Студент получит навыки работы с Git, Vagrant, Packer и публикацией готовых образов в Vagrant Cloud.
В материалах к занятию есть [методичка](https://github.com/dmitry-lyutenko/manual_kernel_update/blob/master/manual/manual.md), в которой описана процедура обновления ядра из репозитория. По данной методичке требуется выполнить необходимые действия. Полученный в ходе выполнения ДЗ Vagrantfile должен быть залит в ваш репозиторий. Для проверки ДЗ необходимо прислать ссылку на него.
Для выполнения ДЗ со * и ** вам потребуется сборка ядра и модулей из исходников.

Критерии оценки: Основное ДЗ - в репозитории есть рабочий Vagrantfile с вашим образом.

ДЗ с *: Ядро собрано из исходников.

ДЗ с **: В вашем образе нормально работают VirtualBox Shared Folders.

## Описание решения
Склонируем репозиторий и положим `Vagrantfile` и скрипты для `packer` в каталог с домашним заданием.
```
cd ~
mkdir hw01
git clone https://github.com/dmitry-lyutenko/manual_kernel_update.git
cp manual_kernel_update/Vagrantfile hw01
cp -r manual_kernel_update/packer hw01
rm -rf manual_kernel_update
```

Установим необходимые инструменты для своей платформы:
* [vagrant](https://www.vagrantup.com/downloads)
* [packer](https://www.packer.io/downloads)

Для переопрделения домашнего каталога `vagrnt`'а, можно определить переменную окружения `VAGRANT_HOME`.

Переходим в директорию с домашним заданием и все дальнейшие команды выполняем оттуда.
```
cd hw01
```
Проверим корректность `Vagrantfile`, поднимем виртуальную машину и подключимся к ней по `ssh`:
```
vagrant validate
vagrant up
vagrant ssh
```
Подключаем community [репозиторий](http://elrepo.org/tiki/HomePage) с ядрами для различных систем:
```
yum install https://www.elrepo.org/elrepo-release-7.el7.elrepo.noarch.rpm
```
Посмотреть список доступных ядер в подключенном репозитории можно командой:
```
yum list kernel* --disablerepo='*' --enablerepo elrepo-kernel
```
В репозитории есть два типа ядер:
* [kernel-lt](http://elrepo.org/tiki/kernel-lt) - **l**ong **t**erm support ядро. Более стаблильное, но и более старое.
* [kernel-ml](http://elrepo.org/tiki/kernel-ml) - ядро из стабильной ветки - **m**ain**l**ine stable branch. Более свежие версии.
Установим свежую версию ядра:
```
sudo yum --enablerepo=elrepo-kernel install kernel-ml
```
Далее необходимо обновить конфигурацию загрузчика, выбрать новое ядро по умолчанию и перезагрущить сервер:
```
sudo grub2-mkconfig -o /boot/grub2/grub.cfg
sudo grub2-set-default 0
sudo reboot
```
После перезагрузки подключаемся к машине и смотрим версию ядра:
```
vagrant ssh
uname -r
```