#!/bin/bash

function create-pool() {
    POOL_NAME=$1
    POOL_PATH=$2
    sudo virsh pool-define-as $POOL_NAME $POOL_PATH
}

function create-volume() {
    POOL_NAME=$1
    VOL_NAME=$2
    VOL_SIZE=$3
    sudo virsh vol-create-as $POOL_NAME ${VOL_NAME}.qcow2 $VOL_SIZE
}

function remove-pool() {
    POOL_NAME=$1
    virsh pool-destroy $POOL_NAME
    #virsh pool-delete $POOL_NAME
    sudo virsh pool-undefine $POOL_NAME
}

function remove-volume() {
    POOL_NAME=$1
    VOL_NAME=$2
    sudo virsh vol-delete ${VOL_NAME}.qcow2 --pool $POOL_NAME
    sudo virsh pool-refresh default
}

function attach-volume() {
    VM_NAME=$1
    DISK_PATH=$2
    TARGET=$3
    sudo virsh attach-disk --domain $VM_NAME --source $DISK_PATH --persistent --target $TARGET
}

function detach-volume() {
    VM_NAME=$1
    TARGET=$2
    sudo virsh detach-disk --domain $VM_NAME --persistent --live --target $TARGET
}

function show-pool() {
    echo "sudo virsh pool-list --all"
    sudo virsh pool-list --all
}

function show-volume() {
    POOL_NAME=$1
    echo "sudo virsh vol-list --all $POOL_NAME"
    sudo virsh vol-list --all $POOL_NAME
    # lsblk --output NAME,SIZE,TYPE
}

echo 'commands:'
echo '  create-pool Pool-Name Directory'
echo '  create-volume Pool-Name Volume-Name Volume-Size'
echo '  remove-pool Pool-Name'
echo '  remove-volume Pool-Name Volume-Name'
echo '  attach-volume Vm-Name Disk-Path Target'
echo '  detach-volume Vm-Name Target'
echo '  show-pool'
echo '  show-volume-list Pool-Name'


