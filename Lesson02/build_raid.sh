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
