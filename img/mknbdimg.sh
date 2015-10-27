#!/bin/bash


d=$1
i=$2


[ ! -d "$d" ] && echo dir $d not readable && exit 1
[ -f "$i" ] && [ ! -w "$i" ] && echo file $f not writable && exit 1
[ -b "$i" ] && echo file $i is block device, bad stuff may happen. exitting.. && exit 1

dd if=/dev/zero of=$i count=12 bs=128MiB
sync
mkfs.ext4 $i
mkdir -p mnt/$d
mount $i mnt/$d
cp -a ${d} mnt/
sync
umount mnt/$d


# mkfs.btrfs -L nbdbr -r $d $i



