#!/bin/bash

. ./slxc.conf

CAPLIST="cap_chown,cap_setgid,cap_setuid,cap_fowner+ep"

setcap $CAPLIST $SLURM_PATH/sbin/slurmstepd
getcap $SLURM_PATH/sbin/slurmstepd