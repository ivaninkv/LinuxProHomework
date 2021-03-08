#!/bin/bash

yum install -y yum-utils
yum install -y wget

sudo yum -y install http://download.zfsonlinux.org/epel/zfs-release.el8_2.noarch.rpm
gpg --quiet --with-fingerprint /etc/pki/rpm-gpg/RPM-GPG-KEY-zfsonlinux
yum-config-manager --enable zfs-kmod
yum-config-manager --disable zfs
yum install -y zfs
modprobe zfs


