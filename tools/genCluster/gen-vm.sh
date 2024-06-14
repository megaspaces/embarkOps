#!/bin/bash

# include variabl config
source ./config

# Variable

# Network
NET_LIST="--network network=$NET_1"
NET_LIST+=" --network network=$NET_2"
NET_LIST+=" --network network=$NET_3"
NET_LIST+=" --network network=$NET_4"
NET_LIST+=" --network network=$NET_5"
NET_LIST+=" --network network=$NET_6"

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
        let ADDR_END=$START_ADDR+$NUM-1
        ADDRESS=$PREFIX$ADDR_END

        sed -i "s/DS_PARAM_ADDR/$ADDRESS/g" $KVM_BUILD_TEMPLATE
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
            echo "---------------------------------------------------------------"
            echo ">>> Already exist - skip: ${INSTANCE_BASE}/${INSTANCE_NAME_PREFIX}-${NUM}"
        else
            echo "Create: $KVM_CONFIG_DIR"
            echo "---------------------------------------------------------------"
            echo ">>> KVM_CONFIG: $KVM_CONFIG"
            echo "---------------------------------------------------------------"
            echo ">>> Source: generate build vm script - $KVM_BUILD_TEMPLATE"
            source $KVM_BUILD_TEMPLATE
            echo "---------------------------------------------------------------"
            echo ">>> Source: build vm - $OUTPUT"
            source $OUTPUT
        fi
    done
    cd $CUR
}

function genvm-create-ansible-inventory()
{
    echo "[servers]" > hosts
    for NUM in $RANGE
    do
		INSTANCE_NAME="${INSTANCE_NAME_PREFIX}-${NUM}"
        let ADDR_END=$START_ADDR+$NUM-1
        ADDRESS=$PREFIX$ADDR_END
        echo "$INSTANCE_NAME ansible_host=$ADDRESS ansible_connection=ssh ansible_port=22 ansible_ssh_user=$RUSER" >> hosts
    done
}

function genvm-create-ansible-inventory-all()
{
    echo "[servers]" > hosts
    for NUM in $RANGE
    do
		INSTANCE_NAME="${INSTANCE_NAME_PREFIX}-${NUM}"
        let ADDR_END=$START_ADDR+$NUM-1
        ADDRESS=$PREFIX$ADDR_END
        let PUBLIC_ADDR_END=$PUBLIC_START_ADDR+$NUM-1
        PUBLIC_ADDR=$PUBLIC_PREFIX$PUBLIC_ADDR_END
        let MGMT_ADDR_END=$MGMT_START_ADDR+$NUM-1
        MGMT_ADDR=$MGMT_PREFIX$MGMT_ADDR_END
        let TENANT_ADDR_END=$TENANT_START_ADDR+$NUM-1
        TENANT_ADDR=$TENANT_PREFIX$TENANT_ADDR_END
        let STORAGE_ADDR_END=$STORAGE_START_ADDR+$NUM-1
        STORAGE_ADDR=$STORAGE_PREFIX$STORAGE_ADDR_END
        let LBAAS_ADDR_END=$LBAAS_START_ADDR+$NUM-1
        LBAAS_ADDR=$LBAAS_PREFIX$LBAAS_ADDR_END
        echo "$INSTANCE_NAME ansible_host=$ADDRESS ansible_connection=ssh ansible_port=22 ansible_ssh_user=$RUSER ansible_public_address=$PUBLIC_ADDR ansible_gateway_address=$GATEWAY_ADDR ansible_end_ip=$ADDR_END ansible_mgmt_address=$MGMT_ADDR ansible_tenant_address=$TENANT_ADDR ansible_storage_address=$STORAGE_ADDR ansible_lbaas_address=$LBAAS_ADDR" >> hosts
    done
}

function genvm-delete-sshkey-gen()
{
    for NUM in $RANGE
    do
        let ADDR_END=$START_ADDR+$NUM-1
        ADDRESS=$PREFIX$ADDR_END
        ssh-keygen -f ~/.ssh/known_hosts -R $ADDRESS
    done
}

function genvm-ssh-keyscan()
{
    for NUM in $RANGE
    do
        let ADDR_END=$START_ADDR+$NUM-1
        ADDRESS=$PREFIX$ADDR_END
        echo "-----------------------------------------"
        echo "ssh-keygen -f ~/.ssh/known_hosts -R $ADDRESS"
        ssh-keygen -f ~/.ssh/known_hosts -R $ADDRESS
        echo "ssh-keyscan -t rsa $ADDRESS >> ~/.ssh/known_hosts"
        ssh-keyscan -t rsa $ADDRESS >> ~/.ssh/known_hosts
    done
}

function genvm-run-ansible()
{
    ansible-playbook -i hosts ansible/ansible-netplan.yml
}

function genvm-run-ansible-all()
{
    ansible-playbook -i hosts ansible/ansible-netplan-public.yml
}

function genvm-create-volume()
{
    VOL_RANGE=$(seq 1 $VOL_COUNT)
    NODE=$1
    for NUM in $VOL_RANGE
    do
        echo sudo virsh vol-create-as $NODE disk-$NUM.qcow2 $VOL_SIZE
        sudo virsh vol-create-as $NODE disk-$NUM.qcow2 $VOL_SIZE
    done
}

function genvm-create-disk()
{
    NODES=`sudo virsh list | grep $INSTANCE_NAME_PREFIX | awk '{print$2}'`
    N=1
    for NODE in $NODES
    do
        genvm-create-volume $NODE
    done
}

function genvm-attach-volume()
{
    VM_NAME=$1
    DISK_ROOT_PATH=$PWD/output/instances/$VM_NAME
    VOL_RANGE=$(seq 1 $VOL_COUNT)
    NODE=$1
    for NUM in $VOL_RANGE
    do
        if [ $NUM -eq 1 ]; then
            TARGET=vdb
        elif [ $NUM -eq 2 ]; then
            TARGET=vdc
        elif [ $NUM -eq 3 ]; then
            TARGET=vdd
        elif [ $NUM -eq 4 ]; then
            TARGET=vde
        elif [ $NUM -eq 5 ]; then
            TARGET=vdf
        fi
        DISK_PATH=$DISK_ROOT_PATH/disk-$NUM.qcow2
        if [ -e $DISK_PATH ]; then
            echo sudo virsh attach-disk --domain $VM_NAME --source $DISK_PATH --persistent --target $TARGET
            sudo virsh attach-disk --domain $VM_NAME --source $DISK_PATH --persistent --target $TARGET
        fi
    done
}

function genvm-attach-disk()
{
    NODES=`sudo virsh list | grep $INSTANCE_NAME_PREFIX | awk '{print$2}'`
    for NODE in $NODES
    do
        genvm-attach-volume $NODE
    done
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
    if ! [ -e ./gen-vm.sh ]; then
        echo "You should do commands!"
        return
    fi

    for NUM in $RANGE
    do
        TargetVM=$INSTANCE_NAME_PREFIX-$NUM
        echo "***************************************************"
        echo "* delete $TargetVM"
        echo " "
        echo "sudo virsh destroy $TargetVM"
        sudo virsh destroy $TargetVM
        echo "sudo virsh undefine $TargetVM"
        sudo virsh undefine $TargetVM
        virsh pool-destroy $TargetVM
        virsh pool-undefine $TargetVM
        echo "rm -rf $INSTANCE_BASE/$TargetVM"
        sudo rm -rf $INSTANCE_BASE/$TargetVM
        echo " "
    done

}

function genvm-show() {
    NODES=`sudo virsh list | grep $INSTANCE_NAME_PREFIX | awk '{print$2}'`
    for NODE in $NODES
    do
        echo ""
        echo "[$NODE]"
        echo ""
        virsh domiflist $NODE
    done
}

function genvm-delete-config()
{
    if ! [ -e ./gen-vm.sh ]; then
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

function genvm-hosts-ping-test()
{
    ansible-playbook -i hosts ansible/ansible-ping-test.yaml -vv
}

function genvm-help()
{
    echo ''
    echo '  Usage: command list '
    echo ''
    echo "      0) genvm-help"
    echo ''
    echo "      1) genvm-create-config"
    echo ''
    echo "      2) genvm-create-vm"
    echo ''
    echo "      3) genvm-ssh-keyscan"
    echo ''
    echo "      4) genvm-create-ansible-inventory"
    echo ''
    echo "      5) genvm-create-ansible-inventory-all"
    echo ''
    echo "      6) genvm-run-ansible"
    echo ''
    echo "      7) genvm-run-ansible-all"
    echo ''
    echo "      8) genvm-delete-sshkey-gen"
    echo ''
    echo "      9) genvm-delete-config"
    echo ''
    echo "      10) genvm-delete-vm"
    #echo ''
    #echo "      $N) genvm-create-disk"
    #echo ''
    #echo "      $N) genvm-attach-disk"
    echo ''
    echo "      11) genvm-get-ip-address"
    echo ''
    echo "      12) genvm-show"
    echo ''
    echo "      13) genvm-hosts-ping-test"
    echo ''
    echo "  input:"
}

main() {
	while :
	do
		genvm-help
		read num
		case $num in
			"q" | "quit") echo "quit"
				break;;
			"0") genvm-help;;
			"1") genvm-create-config;;
     			"2") genvm-create-vm;;
		        "3") genvm-ssh-keyscan;;
		        "4") genvm-create-ansible-inventory;;
		        "5") genvm-create-ansible-inventory-all;;
		        "6") genvm-run-ansible;;
		        "7") genvm-run-ansible-all;;
		        "8") genvm-delete-sshkey-gen;;
		        "9") genvm-delete-config;;
		        "10") genvm-delete-vm;;
		        "11") genvm-get-ip-address;;
			"12") genvm-show;;
            "13") genvm-hosts-ping-test;;
			"*" ) echo "wrong number";;
		esac
	done
}

main

