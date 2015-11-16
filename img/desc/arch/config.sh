#!/bin/bash


dsc=$1
bld=$2

usrs=(dmt mtk)
pkgs=( \
 bash bzip2 coreutils device-mapper dhcpcd diffutils e2fsprogs file  \
 filesystem findutils gawk gcc-libs gettext glibc grep gzip inetutils \
 iproute2 iputils less  linux-lts logrotate nano netctl pacman pciutils \
 procps-ng vi psmisc s-nail sed shadow sysfsutils tar usbutils util-linux  which \
 bash-completion mkinitcpio-nfs-utils openssh btrfs-progs nbd nfs-utils bind-tools \
 rsync openmpi hwloc \
)


# pssh # buggy as of 14.11.2015 use pssh-dmt4 instead
# systemd-sysvcompat 

[ -z "$dsc" ] && exit 1
[ -d "$dsc" ] || exit 1
[ -z "$bld" ] && exit 1
[ -d "$bld" ] && exit 1

mkdir $bld

pacstrap -c -d $bld ${pkgs[@]}
pacman --noconfirm --root $bld --dbpath ${bld}/var/lib/pacman -U \
    ${dsc}/upkg/libcgroup-0.41-2-x86_64.pkg.tar.xz \
    ${dsc}/upkg/mkinitcpio-nbd-0.4.2-1-any.pkg.tar.xz \
    ${dsc}/upkg/pssh-dmt4-2.3.1p-0-any.pkg.tar.xz

arch-chroot $bld groupadd -r compu

for u in ${usrs[@]}; do
    arch-chroot $bld useradd -m -G compu $u
done

if [ ! -f ${dsc}/root/etc/ssh/ssh_host_rsa_key ]; then
    pushd ${dsc}/root/etc/ssh
    ssh-keygen -b 2048 -f ssh_host_rsa_key -N '' -t rsa
    sed s:ssh-rsa:'peer-*,peer-*.coop.cls,10.0.0.* ssh-rsa': ssh_host_rsa_key.pub > ssh_known_hosts
    popd
fi


tar --owner=root --group=root -v -c ${dsc}/root | tar --no-same-owner -x -v --xform="s:${dsc}/root:.:" -C ${bld}/


function mkpkey() {
    d=$1
    mkdir -p $d
    pushd $d
    echo Type passphrase for the key to be put in the future $d directory
    ssh-keygen -b 2048 -f id_rsa -t rsa
    cp id_rsa.pub authorized_keys
    popd
}

for u in ${usrs[@]}; do
    [ -f ${bld}/home/${u}/.ssh/id_rsa ] || mkpkey ${bld}/home/${u}/.ssh
done

[ -f ${bld}/root/.ssh/id_rsa ] || mkpkey ${bld}/root/.ssh


mkdir ${bld}/ovl
arch-chroot $bld systemctl enable sshd
arch-chroot $bld systemctl enable ovl

ln -fs /run/systemd/resolve/resolv.conf ${bld}/etc/resolv.conf
arch-chroot $bld systemctl enable systemd-networkd
arch-chroot $bld systemctl enable systemd-resolved

arch-chroot $bld systemctl enable cgconfig


#patch up a bit
sed s/nfsmount/mount.nfs4/ ${bld}/usr/lib/initcpio/hooks/net > ${bld}/usr/lib/initcpio/hooks/net_nfs4
cp ${bld}/usr/lib/initcpio/install/net{,_nfs4}
# arch-chroot $bld mkinitcpio -A btrfs,net,nbd,systemd -S autodetect,usr,udev,timestamp -k /boot/vmlinuz-linux-lts -g /boot/initramfs-linux-lts.img 
# arch-chroot $bld mkinitcpio -A net,nbd -k /boot/vmlinuz-linux-lts -g /boot/initramfs-linux-lts.img 
arch-chroot $bld mkinitcpio -k /boot/vmlinuz-linux-lts -g /boot/initramfs-linux-lts.img 

rm -f ${bld}/boot/initramfs-linux-{,lts-}fallback.img
ln -s initramfs-linux-lts.img ${bld}/boot/initrd
ln -s vmlinuz-linux-lts       ${bld}/boot/vmlinuz

for u in ${usrs[@]}; do
    arch-chroot $bld chown -R ${u}:${u} /home/${u}
done


