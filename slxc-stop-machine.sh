#!/bin/bash

if [ -z "$1" ]; then
    echo "Need machine name!"
    exit 1
fi

mname="$1"

. ./slxc.conf

# Full path to BUILD
bkp=`pwd`
cd $BUILD
BUILD=`pwd`
cd $bkp

CONTAINERS_DIR="$BUILD/containers"
FSTAB="$BUILD/fstab"
MACHINE_INIT_SCRIPT="$BUILD/machine_init.sh"
CONFIG="$CONTAINERS_DIR/$mname.conf"
MACHINEFILE="$BUILD/machines"
DNSMASQFILE="$BUILD/dnsmasq.conf"
IPFILE="$BUILD/ipnumbering"

CHECK_DIRS="$CONTAINERS_DIR"
CHECK_FILES="$FSTAB $MACHINE_INIT_SCRIPT $CONFIG $MACHINEFILE $DNSMASQFILE $IPFILE"

# Find the machine
if [ ! -f "$MACHINEFILE" ]; then
    echo "No mandatory file $i found. Check consistency!"
    exit 1
fi

machine_ok=0
for i in `cat $MACHINEFILE`; do
    if [ "$i" = "$mname" ]; then
	machine_ok=1
    fi
done

if [ "$machine_ok" = "0" ]; then
    echo "Cannot start machine $mname. Create it first."
    exit 0
fi

lxc-stop -n $mname &