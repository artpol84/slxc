#!/bin/bash


function escape_path()
{
    echo $1 | sed -e 's/\//\\\//g'
}

function network_add()
{
    if [ -z "$1" ]; then
	echo "network_add(): Need machine name!"
	exit 1
    fi
    num=`cat $IPFILE`
    echo "dhcp-host=$1,$IPBASE.$num,$1" >> $DNSMASQFILE
    echo -e "$IPBASE.$num\t$1" >> $HOSTS
    if [ "$new_cntr_fmt" = 1 ]; then
        echo "lxc.net.0.hwaddr = $MACBASE:$num" >> $CONFIG
    else
        echo "lxc.network.hwaddr = $MACBASE:$num" >> $CONFIG
    fi
    num=`expr $num + 1`
    echo "$num" > $IPFILE
    echo "Restart lxc-net service to apply changes!"
}

if [ -z "$1" ]; then
    echo "Need machine name!"
    exit 1
fi

mname="$1"

SLURM_LXC_HOME=`pwd`

. ./slxc.conf

# Check nessesary dirs and file
FSTAB_IN=$TEMPLATES/fstab.in

# Detect lxc.container.config format
new_cntr_fmt=1
tmp=`man lxc.container.conf | grep "lxc.utsname"`
if [ -n "$tmp" ]; then
    # Use the old format
    new_cntr_fmt=0
fi

if [ "$new_cntr_fmt" = 1 ]; then
    SLURM_LXC_CONF_IN=$TEMPLATES/slurm_lxc.conf.new.in
else
    SLURM_LXC_CONF_IN=$TEMPLATES/slurm_lxc.conf.in
fi

MACHINE_INIT_SCRIPT_IN=$TEMPLATES/machine_init.sh.in

CHECK_DIRS="$BUILD $TEMPLATES"
CHECK_FILES="$FSTAB_IN $SLURM_LXC_CONF_IN $MACHINE_INIT_SCRIPT_IN"

for i in $CHECK_DIRS; do
    if [ ! -d "$i" ]; then
        echo "No mandatory directory $i found. Check consistency!"
        exit 1
    fi
done

for i in $CHECK_FILES; do
    if [ ! -f "$i" ]; then
        echo "No mandatory file $i found. Check consistency!"
        exit 1
    fi
done

if [ -z "$IPBASE" ] || [ -z "$MACBASE" ]; then
    echo "Either IPBASE or MACBASE wasn't specifyed!"
    exit 1
fi

# Full path to BUILD
bkp=`pwd`
cd $BUILD
BUILD=`pwd`
cd $bkp

# Create nessesary files and directorys if not exist
CONTAINERS_DIR="$BUILD/containers"
FSTAB="$BUILD/fstab"
HOSTS="$BUILD/hosts"
MACHINE_INIT_SCRIPT="$BUILD/machine_init.sh"
CONFIG="$CONTAINERS_DIR/$mname.conf"
MACHINEFILE="$BUILD/machines"
DNSMASQFILE="$BUILD/dnsmasq.conf"
IPFILE="$BUILD/ipnumbering"


if [ ! -d "$CONTAINERS_DIR" ]; then
    mkdir -p "$CONTAINERS_DIR"
fi

if [ ! -d $SLURM_PATH/var ]; then
    mkdir $SLURM_PATH/var 
fi

if [ ! -f $SLURM_PATH/etc/slurm.conf ]; then
    echo "No $SLURM_PATH/etc/slurm.conf file found. Configure SLURM first"
    exit 1
fi

if [ ! -f "$FSTAB" ]; then
    # Form & Escape it
    MUNGE_VAR=`escape_path $MUNGE_PATH/var/`
    SLURM_VAR=`escape_path $SLURM_PATH/var/`
    cat $FSTAB_IN \
	| sed -e "s/@MUNGEVAR@/$MUNGE_VAR/g" \
	| sed -e "s/@SLURMVAR@/$SLURM_VAR/g" \
	> $FSTAB
fi

if [ ! -f "$HOSTS" ]; then
    # Use existing hosts file as the basis
    cp /etc/hosts $HOSTS
fi

if [ ! -f "$MACHINE_INIT_SCRIPT" ]; then
    # Form & Escape it
    SLURM_LXC_HOME_ESC=`escape_path $SLURM_LXC_HOME`
    cat $MACHINE_INIT_SCRIPT_IN | sed -e "s/@SLURM_LXC_HOME@/$SLURM_LXC_HOME_ESC/g" > $MACHINE_INIT_SCRIPT
    chmod +x $MACHINE_INIT_SCRIPT
fi

if [ ! -f "$MACHINEFILE" ]; then
    touch "$MACHINEFILE"
fi

if [ ! -f "$IPFILE" ]; then
    touch "$IPFILE"
    # TODO: regeneratet the number if dnsmasq.conf is filled
    echo "2" > $IPFILE
fi

if [ ! -f "$DNSMASQFILE" ]; then
    touch "$DNSMASQFILE"
    #TODO: regenerate this if we have machines
fi


# Check for duplication
for i in `cat $MACHINEFILE`; do
    if [ "$i" = "$mname" ]; then
	echo "Machine with name $mname already exist!"
	exit 0
    fi
done

FSTAB_ESC=`escape_path "$FSTAB"`
HOSTS_ESC=`escape_path "$HOSTS"`
cat $SLURM_LXC_CONF_IN | \
	sed -e "s/@NAME@/$mname/g" | \
	sed -e "s/@LXCBRNAME@/$LXC_BRIDGE_NAME/g" | \
	sed -e "s/@FSTAB@/$FSTAB_ESC/g" | \
	sed -e "s/@HOSTS@/$HOSTS_ESC/g" \
	> $CONFIG

echo "$mname" >> $MACHINEFILE
network_add $mname