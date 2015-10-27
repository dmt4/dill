#!/bin/sh
# -*- mode: shell-script; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# ex: ts=8 sw=4 sts=4 et filetype=sh

PATH=/usr/sbin:/usr/bin:/sbin:/bin
command -v getarg >/dev/null    || . /lib/dracut-lib.sh
command -v setup_net >/dev/null || . /lib/net-lib.sh

# Huh? Empty $1?
[ -z "$1" ] && exit 1

# [ ! -z $2 ] means this is for manually bringing up network
# instead of real netroot; If It's called without $2, then there's
# no sense in doing something if no (net)root info is available
# or root is already there
[ -d $NEWROOT/proc ] && exit 0
[ -z "$netroot" ] && exit 1

# Set or override primary interface
netif=$1
[ -e "/tmp/net.bootdev" ] && read netif < /tmp/net.bootdev

case "$netif" in
    ??:??:??:??:??:??)  # MAC address
        for i in /sys/class/net/*/address; do
            mac=$(cat $i)
            if [ "$mac" = "$netif" ]; then
                i=${i%/address}
                netif=${i##*/}
                break
            fi
        done
esac

# Figure out the handler for root=dhcp by recalling all netroot cmdline
# handlers when this is not called from manually network bringing up.
if [ -z "$2" ]; then
    if [ "$netroot" = "dhcp" ] || [ "$netroot" = "dhcp6" ] ; then
        # Load dhcp options
        [ -e /tmp/leaseinfo.$netif.dhcp.ipv4 ] && . /tmp/leaseinfo.$netif.dhcp.ipv4
        [ -e /tmp/leaseinfo.$netif.dhcp.ipv6 ] && . /tmp/leaseinfo.$netif.dhcp.ipv6
        [ -e /tmp/dhclient.$netif.dhcpopts ] && . /tmp/dhclient.$netif.dhcpopts
        [ -z "$new_root_path" ] && new_root_path=$ROOTPATH
        # If we have a specific bootdev with no dhcpoptions or empty root-path,
        # we die. Otherwise we just warn
        if [ -z "$new_root_path" ] ; then
            [ -n "$BOOTDEV" ] && die "No dhcp root-path received for '$BOOTDEV'"
            warn "No dhcp root-path received for '$BOOTDEV' trying other interfaces if available"
            exit 1
        fi

        # Set netroot to new_root_path, so cmdline parsers don't call
        netroot=$new_root_path

        # FIXME!
        unset rootok
        for f in $hookdir/cmdline/90*.sh; do
            [ -f "$f" ] && . "$f";
        done
    else
        rootok="1"
    fi

    # Check: do we really know how to handle (net)root?
    [ -z "$root" ] && die "No or empty root= argument"
    [ -z "$rootok" ] && die "Don't know how to handle 'root=$root'"

    handler=${netroot%%:*}
    handler=${handler%%4}
    handler=$(command -v ${handler}root)
    if [ -z "$netroot" ] || [ ! -e "$handler" ] ; then
        die "No handler for netroot type '$netroot'"
    fi
fi

# Source netroot hooks before we start the handler
source_hook netroot $netif

# Run the handler; don't store the root, it may change from device to device
# XXX other variables to export?
if $handler $netif $netroot $NEWROOT; then
    rm -f -- $hookdir/initqueue/finished/dhcp.sh
    # Network rootfs mount successful - save interface info for ifcfg etc.
    save_netinfo $netif
fi
exit 0
