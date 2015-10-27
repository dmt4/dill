#!/bin/bash


[ "$(whoami)" != "root" ] && sudo $0
[ "$(whoami)" != "root" ] && exit 0

rm -rf  build-root*


desc=desc/suse-leap-42.1-JeOS

pushd ${desc}/root/etc/ssh
ssh-keygen -b 2048 -f ssh_host_rsa_key -N '' -t rsa
sed s:ssh-rsa:'peer-*,peer-*.coop.cls,10.0.0.* ssh-rsa': ssh_host_rsa_key.pub > ssh_known_hosts
popd

function mkpkey() {
    home=$1
    d=${desc}/root/${home}/.ssh
    mkdir -p $d
    pushd $d
    echo Type passphrase for the key to be put in the future $home/.ssh directory
    ssh-keygen -b 2048 -f id_rsa -t rsa
    cp id_rsa.pub authorized_keys
    popd
}

for i in $(xpath  ${desc}/config.xml '/image/users/user[@password=""]//attribute::home' 2>/dev/null); do
#     the eval shall produce the home variable
    eval $i
    [ -f ${desc}/root${home}/.ssh/id_rsa ] || mkpkey $home
done

chown -R ${SUDO_UID}:${SUDO_GID} $desc

kiwi -p $desc -r build-root

./mknbdimg.sh build-root build-root.nbd

