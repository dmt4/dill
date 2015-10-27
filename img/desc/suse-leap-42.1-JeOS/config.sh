#!/bin/bash
#================
# FILE          : config.sh
#----------------
# PROJECT       : OpenSuSE KIWI Image System
# COPYRIGHT     : (c) 2006 SUSE LINUX Products GmbH. All rights reserved
#               :
# AUTHOR        : Marcus Schaefer <ms@suse.de>
#               :
# BELONGS TO    : Operating System images
#               :
# DESCRIPTION   : configuration script for SUSE based
#               : operating systems
#               :
#               :
# STATUS        : BETA
#----------------
#======================================
# Functions...
#--------------------------------------
test -f /.kconfig && . /.kconfig
test -f /.profile && . /.profile

#======================================
# Greeting...
#--------------------------------------
echo "Configure image: [$kiwi_iname]..."

#======================================
# Mount system filesystems
#--------------------------------------
baseMount

#======================================
# Setup baseproduct link
#--------------------------------------
suseSetupProduct

#======================================
# Add missing gpg keys to rpm
#--------------------------------------
suseImportBuildKey

#======================================
# Activate services
#--------------------------------------

# dmt

# get rid of the hardcoded hostname so that the dhcp provided will be used instead
rm -f /etc/hostname

# systemd usually makes the mount points but not on a ro system!
mkdir -p /ovl
suseInsertService ovl

# needed for hostbased auth
suseInsertService sshd
chmod u+s /usr/lib/ssh/ssh-keysign


chown -R munge:munge /etc/munge
suseInsertService munge
suseInsertService slurmd
suseInsertService slurmctld

# do not attempt to delete old kernels cause they dont exist, and root is ro probably anyway
rm -f boot/do_purge_kernels

# mkinitrd -A
mkinitrd
chmod a+r /boot/initrd


#======================================
# Setup default target, multi-user
#--------------------------------------
baseSetRunlevel 3

#==========================================
# remove package docs
#------------------------------------------
# rm -rf /usr/share/doc/packages/*
# rm -rf /usr/share/doc/manual/*
# rm -rf /opt/kde*

#======================================
# only basic version of vim is
# installed; no syntax highlighting
#--------------------------------------
sed -i -e's/^syntax on/" syntax on/' /etc/vimrc

#======================================
# SuSEconfig
#--------------------------------------
suseConfig

#======================================
# Add leap repo
#--------------------------------------
baseRepo="http://download.opensuse.org/distribution/leap/42.1-Current/repo/oss"
baseName="leap-42.1"
zypper ar $baseRepo $baseName

#======================================
# Remove yast if not in use
#--------------------------------------
# suseRemoveYaST

#======================================
# Umount kernel filesystems
#--------------------------------------
baseCleanMount

exit 0
