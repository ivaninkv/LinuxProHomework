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

### Работа с `vagrant`

Склонируем репозиторий и положим `Vagrantfile` и скрипты для `packer` в каталог с домашним заданием.
```bash
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

Для переопределения домашнего каталога `vagrnt`'а, можно определить переменную окружения `VAGRANT_HOME`.

Переходим в директорию с домашним заданием и все дальнейшие команды выполняем оттуда.
```bash
cd hw01
```
Проверим корректность `Vagrantfile`, поднимем виртуальную машину и подключимся к ней по `ssh`:
```bash
vagrant validate
vagrant up
vagrant ssh
```
Подключаем community [репозиторий](http://elrepo.org/tiki/HomePage) с ядрами для различных систем:
```bash
yum install https://www.elrepo.org/elrepo-release-7.el7.elrepo.noarch.rpm
```
Посмотреть список доступных ядер в подключенном репозитории можно командой:
```bash
yum list kernel* --disablerepo='*' --enablerepo elrepo-kernel
```
В репозитории есть два типа ядер:
* [kernel-lt](http://elrepo.org/tiki/kernel-lt) - **l**ong **t**erm support ядро. Более стабильное, но и более старое.
* [kernel-ml](http://elrepo.org/tiki/kernel-ml) - ядро из стабильной ветки - **m**ain**l**ine stable branch. Более свежие версии.
Установим свежую версию ядра:
```bash
sudo yum --enablerepo=elrepo-kernel install kernel-ml
```
Далее необходимо обновить конфигурацию загрузчика, выбрать новое ядро по умолчанию и перезагрузить сервер:
```bash
sudo grub2-mkconfig -o /boot/grub2/grub.cfg
sudo grub2-set-default 0
sudo reboot
```
После перезагрузки подключаемся к машине и смотрим версию ядра:
```bash
vagrant ssh
uname -r
```

### Работа с `packer`

Сначала внесем некоторые изменения в `config.json` для соответствия текущим версиям Centos. Блок `variables`:
```json
"variables": {
    "artifact_description": "CentOS 7.9 with kernel 5.x",
    "artifact_version": "7.9.2009",
    "image_name": "centos-7.9"
  }
```
Изменился алгоритм работы с хэш-суммой образа:
```
"iso_url": "http://mirror.corbina.net/pub/Linux/centos/7.9.2009/isos/x86_64/CentOS-7-x86_64-Minimal-2009.iso",
"iso_checksum": "sha256:07b94e6b1a0b0260b94c83d6bb76b26bf7a310dc78d7a9c7432809fb9bc6194a",
```
Также под `Windows` не заработало добавление пользователя `vagrant` в `sudoers`, поэтому поменяем эту секцию в файле `vagrant.ks`:
```bash
# Add vagrant to sudoers
# cat > /etc/sudoers.d/vagrant << EOF_sudoers_vagrant
# vagrant        ALL=(ALL)       NOPASSWD: ALL
# EOF_sudoers_vagrant
# Add vagrant to sudoers
/bin/echo "vagrant  ALL=(ALL) NOPASSWD:ALL" | /bin/tee /etc/sudoers.d/vagrant
/bin/chmod 0440 /etc/sudoers.d/vagrant
/bin/sed -i "s/^.*requiretty/#Defaults requiretty/" /etc/sudoers
```
Переходим в директорию `packer` и запускаем сборку образа:
```bash
cd packer
packer build centos.json
```
После успешного выполнения команды в директории `packer` появится файл `*.box`. Протестируем его локально:
```bash
vagrant box add --name centos-7-9 centos-7.9.2009-kernel-5-x86_64-Minimal.box
mkdir test
cd test
vagrant init centos-7-9
vagrant up
vagrant ssh
uname -r
```
Удалим тестовый образ из локального хранилища:
```bash
vagrant box remove centos-7-9
```

## работа с Vagrant Cloud

Создаем `box` и публикуем образ в Vagrant cloud
```bash
vagrant cloud box create ivaninkv/centos-7-9
vagrant cloud publish ivaninkv/centos-7-9 1.0 virtualbox centos-7.9.2009-kernel-5-x86_64-Minimal.box -d "Centos 7.9 witn kernel 5.11" --version-description "First version" --release --short-description "Download me!"
```
Не смотря на то, что в [документации](https://www.vagrantup.com/docs/cli/cloud#cloud-box-create) сказано, что по умолчанию `box` создается публичным, у меня создался приватным. Нужно переключить через интерфейс на публичный.

Меняем имя образа в `Vagrantfile` в директории `test` и проверяем работоспособность нашего образа из облака.
```ruby
:box_name => "ivaninkv/centos-7-9"

vagrant up
vagrant ssh
uname -r
```

## Сборка ядра из исходников

Из обсуждения в `slack`'е алгоритм и команды для компиляции ядра и включения `shared_folders` указаны ниже. Вручную на чистой `centos 7` это отрабатывает, но в `packer` не получается - после команд установки `gcc` и перезагрузки сервера не обнаруживается компилятор `gcc`. Разобраться с этим вопросом позже.

Скачать с kernel.org исходники ядра, распаковать их, подготовить на основе старого конфига (.config), который можно сдёрнуть из ядра установленного с elrepo, и включить в этом конфиге два параметра (появились в ядре начиная с версии 5.6.7):
CONFIG_VBOXSF_FS=y
CONFIG_VBOXGUEST=y
и сборка и установка нового ядра.

```bash
# установка зависимостей
sudo yum update -y
sudo yum install -y ncurses-devel make gcc bc bison flex elfutils-libelf-devel openssl-devel grub2 kernel-devel

# установка gcc
sudo yum install -y yum-utils centos-release-scl
sudo yum -y --enablerepo=centos-sclo-rh-testing install devtoolset-7-gcc
echo "source /opt/rh/devtoolset-7/enable" | sudo tee -a /etc/profile
gcc --version

# скачивание, компиляция и установка ядра
curl https://cdn.kernel.org/pub/linux/kernel/v5.x/linux-5.11.tar.xz > linux-5.11.tar.xz
tar -xvf linux-5.11.tar.xz
cd linux-5.11
cp -v /boot/config-$(uname -r) .config
make olddefconfig
echo CONFIG_VBOXSF_FS=y >> .config
echo CONFIG_VBOXGUEST=y >> .config
make
sudo make install

# изменение загрузчика
sudo grub2-mkconfig -o /boot/grub2/grub.cfg
sudo grub2-set-default 0
sudo reboot
uname -r
```