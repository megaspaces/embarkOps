#!/bin/bash

# include variabl config
source ./config

# Variable

# Network
# - NAT/DHCP
VIRTNET=default

# OS 종류
# - command: osinfo-query os
# - sudo apt install libosinfo-bin
# - OS_VARIANT=auto
OS_VARIANT="ubuntu20.04"

KVM_TEMPLATE=$TOP/ubuntu20_template
RANGE=$(seq 1 $VM_COUNT)
OUTPUT_DIR=$TOP/output
CONFIG_BASE=$OUTPUT_DIR/config
INSTANCE_BASE=$OUTPUT_DIR/instances
CONFIG_PREFIX="${CONFIG_BASE}/config-"
NODE_LIST=$CONFIG_BASE/node_list
NODE_ADDR_LIST=$CONFIG_BASE/node_addr_list
NODE_MAP=$CONFIG_BASE/node_map
HOSTNAME_BASE=$INSTANCE_NAME_PREFIX
USERNAME=$RUSER

arg1=$1
arg2=$2
arg3=$3
arg4=$4

# Interface
BrList="--network network=$BR1"
BrList+=" --network network=$BR2"
BrList+=" --network network=$BR3"
BrList+=" --network network=$BR4"
BrList+=" --network network=$BR5"
BrList+=" --network network=$BR6"

# Send commands to remote host
function genvm-cmd()
{
    if [ "$#" -lt 1 ]; then
        echo "%% genvm-cmd: Please enter at least 1 argument (e.g. genvm-cmd ls -l -h) "
        #genvm-help
        return
    fi

    NODES=`cat $NODE_MAP`
    for NODE in $NODES
    do
        HOST_NAME=`echo $NODE | cut -d ':' -f1`
        ADDR=`echo $NODE | cut -d ':' -f2`
        CMD="$1 $2 $3 $4"
        echo "sshpass ssh -o StrictHostKeyChecking=no $RUSER@$ADDR $CMD"
        sshpass ssh -o StrictHostKeyChecking=no $RUSER@$ADDR $CMD
    done
}


function genvm-cp()
{
    if [ "$#" -ne 1 ]; then
        echo "%% genvm-cp: Please enter only 1 argument "
        #genvm-help
        return
    fi

    NODES=`cat $NODE_MAP`
    for NODE in $NODES
    do
        HOST_NAME=`echo $NODE | cut -d ':' -f1`
        ADDR=`echo $NODE | cut -d ':' -f2`
        CMD="$1 $2 $3 $4"
        echo "sshpass scp -o StrictHostKeyChecking=no $1 $RUSER@$ADDR:/home/$USERNAME"
        sshpass scp -o StrictHostKeyChecking=no $1 $RUSER@$ADDR:/home/$USERNAME
    done
}

# Send commands to remote host
function genvm-show-host()
{
    COUNT=0
    NODES=`cat $NODE_MAP`
    for NODE in $NODES
    do
        HOST_NAME=`echo $NODE | cut -d ':' -f1`
        ADDR=`echo $NODE | cut -d ':' -f2`
        COUNT=$(($COUNT+1))
        echo $COUNT $HOST_NAME $ADDR
    done
    echo "Total Host: $COUNT"
}

function genvm-create-config()
{
	for NUM in $RANGE
	do
		INSTANCE_NAME="${INSTANCE_NAME_PREFIX}-${NUM}"
		DS_HOSTNAME=$INSTANCE_NAME
        INSTANCE_DIR=$INSTANCE_BASE/$INSTANCE_NAME
        INSTANCE=$INSTANCE_DIR/$INSTANCE_NAME

	    KVM_CONFIG_DIR="${CONFIG_PREFIX}${NUM}"
        KVM_CONFIG=$KVM_CONFIG_DIR/config
        KVM_BUILD_TEMPLATE=$KVM_CONFIG_DIR/build_template
        OUTPUT=$KVM_CONFIG_DIR/build_vm

        # make directory
        if [ -e $KVM_CONFIG_DIR ]; then
            rm -rf $KVM_CONFIG_DIR
        fi
        mkdir $KVM_CONFIG_DIR -p

        # generate config
        echo "KVM_CONFIG: $KVM_CONFIG, DS_HOSTNAME: $DS_HOSTNAME"
 		echo "#!/bin/bash" > $KVM_CONFIG
		echo "" >> $KVM_CONFIG
		echo "# Image Path" >> $KVM_CONFIG
		echo "IMAGE=$IMAGE" >> $KVM_CONFIG
		echo "" >> $KVM_CONFIG
		echo "# Instance Information" >> $KVM_CONFIG
		echo "INSTANCE_NAME=$INSTANCE_NAME" >> $KVM_CONFIG
		echo "INSTANCE_DIR=$INSTANCE_DIR" >> $KVM_CONFIG
		echo "INSTANCE=$INSTANCE.qcow2" >> $KVM_CONFIG
		echo "" >> $KVM_CONFIG
		echo "# Hostname" >> $KVM_CONFIG
		echo "HOSTNAME=$DS_HOSTNAME" >> $KVM_CONFIG
		echo "" >> $KVM_CONFIG
		echo "# OS Type" >> $KVM_CONFIG
		echo "OS_VARIANT=$OS_VARIANT" >> $KVM_CONFIG
		echo "" >> $KVM_CONFIG
		echo "# HOST Username" >> $KVM_CONFIG
		echo "USERNAME=$USERNAME" >> $KVM_CONFIG
		echo "" >> $KVM_CONFIG
		echo "# Physical Resource" >> $KVM_CONFIG
		echo "RAM=$RAM" >> $KVM_CONFIG
		echo "CPU=$CPU" >> $KVM_CONFIG
		echo "DISK_SIZE=$DISK" >> $KVM_CONFIG
		echo "" >> $KVM_CONFIG
		echo "# Output Filename" >> $KVM_CONFIG
		echo "OUTPUT=$OUTPUT" >> $KVM_CONFIG

        # copy template
        cp $KVM_TEMPLATE $KVM_BUILD_TEMPLATE
        sed -i "s/DS_PARAM_CONFIG/config/g" $KVM_BUILD_TEMPLATE
        sed -i "s/DS_PARAM_USER_DATA/user-data/g" $KVM_BUILD_TEMPLATE
        sed -i "s/DS_PARAM_META_DATA/meta-data/g" $KVM_BUILD_TEMPLATE
	done
}

function genvm-create-vm()
{
    CUR=$PWD
    for NUM in $RANGE
    do
        KVM_CONFIG_DIR="${CONFIG_PREFIX}${NUM}"
        KVM_CONFIG=$KVM_CONFIG_DIR/config
        KVM_BUILD_TEMPLATE=$KVM_CONFIG_DIR/build_template
        OUTPUT=$KVM_CONFIG_DIR/build_vm

        cd $KVM_CONFIG_DIR

        if [ -e ${INSTANCE_BASE}/${INSTANCE_NAME_PREFIX}-${NUM} ]; then
            echo "--------------------------------------------------------------------------------------"
            echo ">>> Already exist - skip: ${INSTANCE_BASE}/${INSTANCE_NAME_PREFIX}-${NUM}"
        else
            echo "Create: $KVM_CONFIG_DIR"
            echo "[1]-----------------------------------------------------------------------------------"
            echo ">>> KVM_CONFIG: $KVM_CONFIG"
            echo "[2]-----------------------------------------------------------------------------------"
            echo ">>> Source: generate build vm script - $KVM_BUILD_TEMPLATE"
            source $KVM_BUILD_TEMPLATE
            echo "[3]-----------------------------------------------------------------------------------"
            echo ">>> Source: build vm - $OUTPUT"
            source $OUTPUT
        fi
    done
    cd $CUR
}

function genvm-get-ip-address()
{
    NODES=`sudo virsh list | grep $INSTANCE_NAME_PREFIX | awk '{print$2}'`
    N=1
    for NODE in $NODES
    do
        ADDR=`sudo virsh domifaddr $NODE |grep ipv4 | awk '{print$4}' | awk -F / '{print$1}'`
        if [ $N -eq 1 ]; then
            echo $NODE > $NODE_LIST
            echo $ADDR > $NODE_ADDR_LIST
            echo "$ADDR $NODE" > $NODE_MAP
        else
            echo $NODE >> $NODE_LIST
            echo $ADDR >> $NODE_ADDR_LIST
            echo "$ADDR $NODE" >> $NODE_MAP
        fi
        N=$(($N+1))
    done
    cat $NODE_MAP
}

function genvm-delete-vm()
{
    if ! [ -e ./genvm-cmds.sh ]; then
        echo "You should do commands!"
        return
    fi

    for NUM in $RANGE
    do
        TargetVM=$INSTANCE_NAME_PREFIX-$NUM
        echo "***************************************************"
        echo "* delete $TargetVM"
        echo " "
        echo "sudo virsh shutdown $TargetVM"
        sudo virsh shutdown $TargetVM
        echo "sudo virsh undefine $TargetVM"
        sudo virsh undefine $TargetVM
        echo "rm -rf $INSTANCE_BASE/$TargetVM"
        sudo rm -rf $INSTANCE_BASE/$TargetVM
        echo " "
    done

}

function genvm-delete-config()
{
    if ! [ -e ./genvm-cmds.sh ]; then
        echo "You should do commands!"
        return
    fi

    sudo rm -rf $CONFIG_BASE/*
}

function genvm-clear-ssh-keygen()
{
    genvm-get-ip-address
    NODES=`cat $NODE_MAP`
    for NODE in $NODES
    do
        HOST_NAME=`echo $NODE | cut -d ':' -f1`
        ADDR=`echo $NODE | cut -d ':' -f2`
        if [ x$ADDR == x ]; then
            echo "$NODE dose not get IP Address!"
        else
            echo "ssh-keygen -f \"/$HOME/.ssh/known_hosts\" -R \"$ADDR\""
            ssh-keygen -f "/$HOME/.ssh/known_hosts" -R "$ADDR"
        fi
    done
}

function genvm-help()
{
    N=1
    echo ''
    echo '  Usage: command list '
    echo ''
    echo "      $N) genvm-help"
    echo ''
    N=$(($N+1))
    echo "      $N) genvm-create-config"
    echo ''
    N=$(($N+1))
    echo "      $N) genvm-create-vm"
    echo ''
    N=$(($N+1))
    echo "      $N) genvm-delete-config"
    echo ''
    N=$(($N+1))
    echo "      $N) genvm-delete-vm"
    echo ''
    N=$(($N+1))
    echo "      $N) genvm-get-ip-address"
    echo ''
}

genvm-help

