# HPC cluster with openSUSE Leap in minutes

Diskless mode with network mounted root. Deployment to 
local drive shall be simple to add. Possible to replicate on other systemd 
based distros.


## Contents

* openSUSE Leap (SLE 12 base) rootfs build with KIWI
* kernel v4.1.11
* pxe boot
* isolated dhcp and key authenticated dynamic dns on private ipv4 subnet
* nfsv4 or nbd mounter root with normal/stock initrd
* overlayfs mounted on /etc and /var, tmpfs on /tmp
* pssh for flexible runs at scale
* host based authentication for regular users
* slurm queuing and scheduling system

Ephemeral:
* run in systemd scope for easy tracking of daemons
* kvm with host cpu pass through
* virtual switch networking with vde


## Setup

Download/clone, make sure image schemaversion="6.2" for openSUSE Tumbleweed 
and 6.1 for 13.2. Run `./run.sh`.

On first run there will be questions about passphrases for the ssh keys. 


## Connect

Passwords are disabled. Use the auto generated key to access, e.g.

    host:~> ssh 10.0.0.3 -l dill -i dnl/dill/img/build-root/home/dill/.ssh/id_rsa 
    The authenticity of host '10.0.0.3 (10.0.0.3)' can't be established.
    RSA key fingerprint is bc:2f:d2:80:65:56:e0:4a:3a:bb:bd:c0:15:87:56:ca [MD5].
    Are you sure you want to continue connecting (yes/no)? yes
    Warning: Permanently added '10.0.0.3' (RSA) to the list of known hosts.
    Enter passphrase for key 'dnl/dill/img/build-root/home/dill/.ssh/id_rsa': 
    This is the Leap 42.1 JeOS SuSE Linux System.
    dill@peer-003:~> sinfo
    PARTITION AVAIL  TIMELIMIT  NODES  STATE NODELIST
    infall*      up   infinite      4   idle peer-[002-005]
    dill@peer-003:~> srun -N 4 hostname 
    peer-003
    peer-002
    peer-005
    peer-004
    dill@peer-003:~> 


## Shutdown

Pressing ctrl+c or sending SIGINT shall be enough. If in trouble,
stop all processes with a single command

    sudo sytemctld stop dill.scope

If in doubt, try

    > systemctl status dill.scope
    ● dill.scope
       Loaded: not-found (Reason: No such file or directory)
       Active: inactive (dead)


## TODO

* Streamline configuration
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

