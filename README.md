# Setup a virtual hpc cluster with opensuse 'leap' in seconds

Diskless mode with root on network block device. Deployment to 
local drive is simple to add. Using other systemd based distros 
shall be possible too.


## Contents

* kvm with host cpu pass through
* virtual switch networking with vde
* openSUSE Leap (SLE 12 base) rootfs build with KIWI
* kernel v4.1.11
* pxe boot
* nfsv4 or nbd mounter root with normal/stock initrd
* isolated dhcp and key authenticated dynamic dns on private ipv4 subnet
* pssh for flexible runs at scale
* host based authentication for regular users
* slurm queuing and scheduling system
* run in systemd scope for easy tracking of daemons

## Setup

Download/clone, make sure image schemaversion="6.2" for openSUSE Tumbleweed 
and 6.1 for 13.2. Run `./dill.sh`.

On first run there will be questions about passphrases for the ssh keys. 


## Connect

Passwords are disabled.

    ssh 10.0.0.3 -i /path/to/cloned/repo/img/desc/suse-leap-42.1-JeOS/root/home/user/.ssh/id_rsa -l user

There may be some trouble with permissions..


## When in trouble

Stop all processes with a single command

    systemctld stop dill.scope


## TODO

* Try IPv6
* Masquerade host net device to allow inet access
* Export /opt and $HOME with NFS.
* Add stuff to /opt.
* Extend to pNFS.
* Add systemd unit for deployment to local disk.
* Cover ArchLinux


## See also

* PelicanHPC
* Warewulf
* Rocks
* xCAT
* Cobbler

