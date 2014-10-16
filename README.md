slxc
====

SLURM in Linux Containers

The set of scripts to easily deploy SLURM cluster on one machine using Linux Containers.
The goal is SLURM development mostly. Any other ideas/usages :)?

Prerequisites: `screen` tool.

1. Install Linux Containers (LXC)
2. Configure LXC (the following is Ubuntu/Mint specific, for other distributions check its manuals to use the proper paths and configuration files names):
  - Setup LXC networking (`/etc/default/lxc-net`): 
    * `USE_LXC_BRIDGE="true"`
    * `LXC_DHCP_CONFILE=/etc/lxc/dnsmasq.conf`
    * `LXC_DOMAIN="lxc"`
  - Change `/etc/lxc/dnsmasq.conf` adding following line:
    * `conf-file=$SLXC_PATH/build/dnsmasq.conf`
3. Install **Munge** in `MUNGE_PATH` (under `someuser`). **NOTE!** that *munge-0.5.11* has problems with user-defined prefix installation (see https://code.google.com/p/munge/issues/detail?id=34 for the details). In the mentioned issue report you may find the patch that temporally fixes this problem. Or you can use more recent versions that have this problem fixed.
4. Install **SLURM** in `SLURM_PATH` (under `someuser`). Make additional directorys in slurm's prefix: `mkdir $SLURM_PATH/var $SLURM_PATH/etc`
5. Configure SLURM and put its configuration in `$SLURM_PATH/etc/slurm.conf`. While configuring select your favorite domain names for the frontend and compute nodes. Here we will use `frontend` and `cnX`.
6. Put SLURM and Munge installation paths to `$SLXC_PATH/slxc.conf`.
7. Set `SLURM_USER` to `someuser` in `$SLXC_PATH/slxc.conf`.
8. Create cluster machines with `slxc-new-node.sh`. The only argument of `slxc-new-node.sh` is machine hostname. NOTE that you must use the same frontend/compute nodes names as in `$SLURM_PATH/etc/slurm.conf`.
  - Create frontend first (let's call it "frontend" for example ):
    * `$SLXC_PATH/slxc-new-node.sh frontend`
  - Create node machines (cn1, cn2, ..., cnN):
    * `$ for i in $(seq 1 N); do $SLX_PATH/slxc-new-node.sh cn$i; done`
9. [Optional] Add Munge and SLURM installation paths to your PATH environment variable.
    And `export SLURM_CONF=$SLURM_PATH/etc/slurm.conf` to let `sinfo`, `sbatch`
    and others know how to reach `slurmctld`.
10. Restart lxc-net service (for Ubuntu/Mint):
  - `$ sudo service lxc-net restart`
11. Start your cluster:
  - `$ sudo ./slxc-run-cluster.sh`
12. Verify that everything is OK (both tools should show all your virtual "machines" running):
  - `$ sudo screen -ls`
  - `$ sudo lxc-ls --active`
13. Now you can attach to any machine with
  - `$ sudo lxc-attach -n $nodename`
14. To shutdown your cluster use
  - `$ ./slxc-stop-cluster.sh`
  - NOTE: that it may take a while. You can speedup this process by setting
`LXC_SHUTDOWN_TIMEOUT` in `/etc/default/lxc` (for Ubuntu and Mint)

That seems to be all. Enjoy!
