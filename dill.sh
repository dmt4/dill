#!/bin/bash

ma=( \
    52:54:0e:93:25:76 \
    52:54:9d:84:d4:42 \
    52:54:f1:b4:ed:77 \
    52:54:15:7c:4a:27 \
    52:54:a6:22:d2:86 \
    52:54:fc:c1:52:f4 \
    52:54:46:ef:a8:f5 \
    52:54:26:9e:24:19 \
    52:54:33:87:6b:d0 \
)

##########################################3

bins=(systemctl systemd-run vde_switch \
    dhcpd named rndc-confgen atftpd \
    rpc.mountd rpc.nfsd exportfs  \
    nbd-server qemu-system-x86_64   \
    kiwi mkfs.ext4 xpath ssh-keygen \
)

for i in ${bins[@]} ; do
    which $i
    if [ "$?" != "0" ]; then
        echo get yourself $i and try again, exitting now ...
        exit 1
    fi
done

systemctl is-active --quiet dill.scope
if [ "$?" != "0" ]; then
    sudo -E systemd-run --scope --send-sighup --unit=dill $0
    exit $?
fi

function cleanup {
    exportfs -f
    exportfs -ua
    rpc.nfsd -H 10.0.0.1 0

    rndc stop 2>/dev/null
    rm -f named/run/*.{jnl,zone,hint}
    rm -f dhcpd/dhcpd.lease
}

cleanup

modprobe tun
vde_switch -daemon -tap tap0 -group users -mod 660
ip addr add 10.0.0.1/24 dev tap0
ip link set dev tap0 up

n=${#ma[*]}
# echo ${ma[*]}
echo $n

# # coop peon jack heap ants peer escadrille
pushd named
sed s:'\bPPWD\b':"$OLDPWD":g conf/named.conf.in > conf/named.conf
[ -f conf/rndc.key ] || rndc-confgen -a -c `pwd`/conf/rndc.key
mkdir -p run
cp -a conf/*.{zone,hint} run/
chown -R named:named conf run
named -4 -c `pwd`/conf/named.conf -n 1 -U 1 -u named # -D coop.cls
popd

pushd dhcpd
cp -a ../named/conf/rndc.key ./
chown dhcpd rndc.key
touch dhcpd.lease
dhcpd -4 -q -cf dhcpd.conf -lf dhcpd.lease -pf dhcpd.pid tap0
popd

atftpd --daemon --no-fork  --bind-address 10.0.0.1 --user $SUDO_USER --group users  --pidfile atftpd.pid `pwd`/tftpboot &

if [ ! -d img/build-root ]; then
    pushd img
    ./rebuild.sh
    sync
    popd
fi

# on leap 42 overlayfs cannot use nfs as lowerdir making it impossible to have ro nfsroot + tmpfs cow
modprobe nfsd
sleep 0.25
rpc.mountd --no-nfs-version 2 --no-nfs-version 3 -f `pwd`/exports #-F
rpc.nfsd -H 10.0.0.1 -N 2 -N 3 4
exportfs -f
exportfs -au
exportfs -i -o rw,no_root_squash,no_subtree_check,fsid=0 10.0.0.0/24:`pwd`/img/build-root
# exportfs -i -o rw,no_subtree_check,fsid=0 10.0.0.0/24:`pwd`/shares


if [ ! -f img/build-root.nbd ]; then
    pushd img
    ./mknbdimg.sh build-root build-root.nbd
    sync
    popd
fi

# it shall be possible to disable cow on the nbdroot to turn it in ro root then mount local tmpfs overlay on var since the netwok serves proper blockdev fs
pushd nbd
sed s:'\bPPWD\b':"$OLDPWD":g nbd.conf.in > nbd.conf
nbd-server -C nbd.conf
popd

for i in ${ma[@]}; do
    echo $i
    sudo -E -u $SUDO_USER \
        qemu-system-x86_64 -enable-kvm -cpu host -m 2GiB \
            -net nic,macaddr=$i -net vde  \
            -smp cores=2,threads=2,sockets=1 &
done

trap "{ cleanup; systemctl stop dill.scope; }" SIGINT

wait



systemctl stop dill.scope
