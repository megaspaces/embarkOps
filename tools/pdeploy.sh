#!/bin/bash

UNDER_PREFIX="cvm"
OVER_PREFIX="host"
UNDER_NUM=1
HOST_NUM=3
OVER_HOST_IMAGE=88a22092-4c2a-4328-a7b5-17d565e87a4e
UNDER_HOST_IMAGE=88a22092-4c2a-4328-a7b5-17d565e87a4e


###################################################################################################################################################################################
# 1. Configure Network

# 1.1 Create Networks
create_networks() {
	openstack --insecure network create --disable-port-security $OS_PROJECT_NAME-br-mgmt> /dev/null
	openstack --insecure subnet create --subnet-range 10.1.1.0/24 --network $OS_PROJECT_NAME-br-mgmt $OS_PROJECT_NAME-br-mgmt-subnet1 > /dev/null
}

# 1.2 Create ports in networks
create_ports() {
	for ((i=1; i <= $UNDER_NUM; i++));
	do
		openstack --insecure port create --network $OS_PROJECT_NAME-br-mgmt --fixed-ip ip-address=10.1.1.2$i $OS_PROJECT_NAME-br-mgmt-$UNDER_PREFIX$i > /dev/null
		openstack --insecure port create --network provider --fixed-ip ip-address=192.168.xxx.xx$(($i+6)) --disable-port-security $OS_PROJECT_NAME-br-public-$UNDER_PREFIX$i > /dev/null
	done

	for ((i=1; i <= $HOST_NUM; i++));
	do
		openstack --insecure port create --network $OS_PROJECT_NAME-br-mgmt --fixed-ip ip-address=10.1.1.1$i $OS_PROJECT_NAME-br-mgmt-$OVER_PREFIX$i > /dev/null
		openstack --insecure port create --network provider --fixed-ip ip-address=192.168.xxx.xx$i --disable-port-security $OS_PROJECT_NAME-br-public-$OVER_PREFIX$i > /dev/null
	done
}

# 1.3 Delete ports in networks
delete_ports() {
	for ((i=1; i <= $UNDER_NUM; i++));
        do
                openstack --insecure port delete $OS_PROJECT_NAME-br-mgmt-$UNDER_PREFIX$i > /dev/null
                openstack --insecure port delete $OS_PROJECT_NAME-br-public-$UNDER_PREFIX$i > /dev/null
        done

	for ((i=1; i <= $HOST_NUM; i++));
        do
                openstack --insecure port delete $OS_PROJECT_NAME-br-mgmt-$OVER_PREFIX$i > /dev/null
                openstack --insecure port delete $OS_PROJECT_NAME-br-public-$OVER_PREFIX$i > /dev/null
        done
}

# 1.4 Delete networks
delete_networks() {
    openstack --insecure network delete $OS_PROJECT_NAME-br-mgmt > /dev/null
    openstack --insecure network delete $OS_PROJECT_NAME-br-lbaas > /dev/null
}

###################################################################################################################################################################################
# 2. Configure Virtual Machines

# 2.1 Set Default Volume Type
set_volume_type() {
	PROJECT_ID=$(openstack --insecure project show $OS_PROJECT_NAME | grep ' id' | awk '{print $4}')
	cinder --insecure default-type-set volumes_ssd $PROJECT_ID
}

# 2.2 Create Overcloud hosts
create_over_hosts() {
	for ((i=1; i <= $HOST_NUM; i++));
	do
		openstack --insecure server create --flavor c8m16 --image $OVER_HOST_IMAGE --boot-from-volume 200 \
			--block-device volume_size=50,destination_type=volume,delete_on_termination=true \
			--block-device volume_size=50,destination_type=volume,delete_on_termination=true \
			--port $OS_PROJECT_NAME-br-mgmt-$OVER_PREFIX$i \
			--port $OS_PROJECT_NAME-br-public-$OVER_PREFIX$i \
			$OVER_PREFIX$i > /dev/null
	done
}

# 2.3 Create Undercloud hosts
create_under_hosts() {
	for ((i=1; i <= $UNDER_NUM; i++));
	do
       		openstack --insecure server create --flavor c8m16 --image $UNDER_HOST_IMAGE --boot-from-volume 60 \
                --port $OS_PROJECT_NAME-br-mgmt-$UNDER_PREFIX$i \
                --port $OS_PROJECT_NAME-br-public-$UNDER_PREFIX$i \
        		$UNDER_PREFIX$i > /dev/null
	done
}

# 2.4 Delete Overcloud hosts
delete_over_hosts() {
	VOLUMES=$(openstack --insecure volume list | grep vda | grep $OVER_PREFIX | awk '{ print $2 }')

	for ((i=1; i <= $HOST_NUM; i++));
        do
                openstack --insecure server delete $OVER_PREFIX$i > /dev/null
        done
	sleep 30
	openstack --insecure volume delete $VOLUMES > /dev/null
}

# 2.5 Delete Undercloud hosts
delete_under_hosts() {
	VOLUMES=$(openstack --insecure volume list | grep vda | grep $UNDER_PREFIX | awk '{ print $2 }')

	for ((i=1; i <= $UNDER_NUM; i++));
	do
		openstack --insecure server delete $UNDER_PREFIX$i > /dev/null
	done
	sleep 30
	openstack --insecure volume delete $VOLUMES > /dev/null
}

###################################################################################################################################################################################
# 3. Etc.

deploy_all() {
	create_networks
	create_ports
	create_over_hosts
	create_under_hosts
}

delete_all() {
	delete_over_hosts
	delete_under_hosts
	delete_ports
	sleep 20
	delete_networks
}

deploy_help() {
    echo ''
    echo '  Usage: command list '
    echo ''
    echo "      0) deploy_all"
    echo "      1) create_networks"
    echo "      2) create_ports"
    echo "      3) create_over_hosts"
    echo "      4) create_under_hosts"
    echo "      5) delete_over_hosts"
    echo "      6) delete_under_hosts"
    echo "      7) delete_ports"
    echo "      8) delete_networks"
    echo "      9) delete_all"
    echo ''
    echo "  input:"
}

main() {
	set_volume_type
	while :
	do
		deploy_help
		read num
		case $num in
			"q" | "quit") echo "quit"
				break;;
			"0") deploy_all;;
			"1") create_networks;;
			"2") create_ports;;
			"3") create_over_hosts;;
			"4") create_under_hosts;;
			"5") delete_over_hosts;;
			"6") delete_under_hosts;;
			"7") delete_ports;;
			"8") delete_networks;;
			"9") delete_all;;
			"*" ) echo "wrong number";;
		esac
	done
}

main
