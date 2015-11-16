#!/bin/bash


[ "$(whoami)" != "root" ] && sudo $0
[ "$(whoami)" != "root" ] && exit 0

dsc=desc/arch
bld=build-root-arch

rm -rf $bld

${dsc}/config.sh $dsc $bld

./mknbdimg.sh $bld ${bld}.nbd



