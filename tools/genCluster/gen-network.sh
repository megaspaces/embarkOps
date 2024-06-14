#!/bin/bash

declare -a net_list=("br1_popcon" "br_public" "br1_mgmt" "br1_tenant" "br1_storage" "br1_lb")

function start-bridge() {
        cat >bridge_tmp.xml <<EOF
<network>
        <name>${BR_NAME}</name>
        <forward mode='bridge' />
        <bridge name='${BR_NAME}' />
</network>
EOF
        sudo virsh net-define bridge_tmp.xml
        sudo virsh net-start ${BR_NAME}
        sudo virsh net-autostart ${BR_NAME}
        rm bridge_tmp.xml
}

function stop-bridge() {
        sudo virsh net-destroy ${BR_NAME}
        sudo virsh net-undefine ${BR_NAME}
}

function show-bridges() {
    virsh net-list --all
}

function start-bridges() {
        for i in "${net_list[@]}"
        do
                BR_NAME=$i
                start-bridge
        done
}

function stop-bridges() {
        for i in "${net_list[@]}"
        do
                BR_NAME=$i
                stop-bridge
        done
}

function gennet-help() {
	echo "  Usage: command list"
	echo ""
	echo "	0) gennet-help"
	echo ""
	echo "	1) show-bridges"
	echo ""
	echo "	2) start-bridges"
	echo ""
	echo "	3) stop-bridges"
	echo ""
	echo "  input:"
}

main() {
	while :
        do
                gennet-help
                read num
                case $num in
                        "q" | "quit") echo "quit"
                                break;;
                        "0") gennet-help;;
                        "1") show-bridges;;
                        "2") start-bridges;;
                        "3") stop-bridges;;
                        "*" ) echo "wrong number";;
                esac
        done
}

main
