#!/bin/bash

. ./slxc.conf

MACHINEFILE="$BUILD/machines"

# Find the machine
if [ ! -f "$MACHINEFILE" ]; then
    echo "No mandatory file $i found. Check consistency!"
    exit 1
fi

for i in `cat $MACHINEFILE`; do 
    ./slxc-stop-machine.sh  $i
done