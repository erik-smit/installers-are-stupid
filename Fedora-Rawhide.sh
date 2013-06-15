#!/bin/bash
set -x
set -e

sfdisk /dev/sda << EOF
1,;
EOF

mkfs.ext4 -j /dev/sda1

mkdir /mnt/system
mount /dev/sda1 /mnt/system

rpm --root=/mnt/system --initdb
rpm --root=/mnt/system --nodeps -ivh \
  http://nl.mirror.eurid.eu/fedora/linux/development/rawhide/x86_64/os/Packages/f/fedora-release-20-0.1.noarch.rpm \
  http://nl.mirror.eurid.eu/fedora/linux/development/rawhide/x86_64/os/Packages/f/fedora-release-rawhide-20-0.1.noarch.rpm

yum --assumeyes --installroot=/mnt/system groupinstall "Minimal Install"

cd /mnt/system
cp /etc/resolv.conf etc
cat > etc/fstab << EOF
UUID=`blkid -s UUID -o value /dev/sda1` / ext4 defaults 0 0
EOF

for i in dev proc run sys; do
  mount --bind /$i $i
done
chroot . systemd-machine-id-setup

chroot . yum --assumeyes install kernel grub2

chroot . grub2-mkconfig > boot/grub2/grub.cfg
chroot . grub2-install /dev/sda
