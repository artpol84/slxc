slxc
====

SLURM in Linux Containers

The set of scripts to easily deploy SLURM cluster on one machine using Linux Containers.
The goal is SLURM development mostly. Any other ideas/usages :)?

Prerequisites: `screen` tool.

1. Install Linux Containers (LXC)
  - In Linux Mint (and probably Ubuntu) need the following packages:
    * `lxc-dev`
    * `lxc-utils`
2. Configure LXC (the following is Ubuntu/Mint specific, for other distributions check its manuals to use the proper paths and configuration files names):
  - Setup LXC networking (`/etc/default/lxc-net`): 
    * `USE_LXC_BRIDGE="true"`
    * `LXC_DHCP_CONFILE=/etc/lxc/dnsmasq.conf`
    * `LXC_DOMAIN="lxc"`
  - Change `/etc/lxc/dnsmasq.conf` adding following line:
    * `conf-file=$SLXC_PATH/build/dnsmasq.conf`
  - If facing problems, check https://github.com/lxc/lxc/pull/285/files (look in /etc/apparmor.d/abstractions/lxc/start-container)
3. Install **Munge** in `MUNGE_PATH` (under `someuser`). **NOTE!** that *munge-0.5.11* has problems with user-defined prefix installation (see https://code.google.com/p/munge/issues/detail?id=34 for the details). In the mentioned issue report you may find the patch that temporally fixes this problem. Or you can use more recent versions that have this problem fixed.
4. [Optional] If the **SLURM_USER** is not root and you plan to submit jobs as user **USER1** != **SLURM_USER**:
  - Apply the patch from SLURM directory:
    * `patch -p1 < <slxc_path>/patch/start_from_user.patch`
5. Install **SLURM** in `SLURM_PATH` (under `someuser`). Make additional directorys in slurm's prefix: 
  - `mkdir $SLURM_PATH/var $SLURM_PATH/etc`
6. Configure SLURM and put its configuration in `$SLURM_PATH/etc/slurm.conf`. While configuring select your favorite domain names for the frontend and compute nodes. Here we will use `frontend` and `cnX`.
7. Put SLURM and Munge installation paths to `$SLXC_PATH/slxc.conf`.
8. Set `SLURM_USER` to `someuser` in `$SLXC_PATH/slxc.conf`.
9. Create cluster machines with `slxc-new-node.sh`. The only argument of `slxc-new-node.sh` is machine hostname. NOTE that you must use the same frontend/compute nodes names as in `$SLURM_PATH/etc/slurm.conf`.
  - Create frontend first (let's call it "frontend" for example ):
    * `$SLXC_PATH/slxc-new-node.sh frontend`
  - Create node machines (cn1, cn2, ..., cnN):
    * `$ for i in $(seq 1 N); do $SLX_PATH/slxc-new-node.sh cn$i; done`
10. [Optional] Add Munge and SLURM installation paths to your PATH environment variable.
    And `export SLURM_CONF=$SLURM_PATH/etc/slurm.conf` to let `sinfo`, `sbatch`
    and others know how to reach `slurmctld`.
11. Restart lxc-net service (for Ubuntu/Mint):
  - `$ sudo service lxc-net restart`
12. [Optional] If the **SLURM_USER** is not root and you plan to submit jobs as user **USER1** != **SLURM_USER**:
  - Setup SLURM capabilities:
    * `$ sudo ./slurm-set-capabilities.sh`
13. Start your cluster:
  - `$ sudo ./slxc-run-cluster.sh`
14. Verify that everything is OK (both tools should show all your virtual "machines" running):
  - `$ sudo screen -ls`
  - `$ sudo lxc-ls --active`
15. Now you can attach to any machine with
  - `$ sudo lxc-attach -n $nodename`
16. [Optional] If you plan use PMIx plugin, then required to be set the temporary directory of PMIx through value of environment **SLURM_PMIX_TMPDIR**. This path shouldn't be equal to shared directory between virtual containers. The env required to set before `srun` use.
  - Set PMIx tmp dir:
    * `$ export SLURM_PMIX_TMPDIR=$SLURM_PATH/var/spool`
17. To shutdown your cluster use
  - `$ ./slxc-stop-cluster.sh`
  - NOTE: that it may take a while. You can speedup this process by setting
`LXC_SHUTDOWN_TIMEOUT` in `/etc/default/lxc` (for Ubuntu and Mint)

That seems to be all. Enjoy!
