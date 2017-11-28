#!/bin/bash

#
#   REMEMBER TO check syntax with https://github.com/koalaman/shellcheck
#
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 
   exit 1
fi
#set -x          # debug enabled
set -e          # exit on first error
set -o pipefail # exit on any errors in piped commands

#ENVIRONMENT VARIABLES

# @info:	current version
declare VERSION="1.0.0"

export BASE_PATH="/vagrant"
export TMP_PATH="${BASE_PATH}/tmp"

# Attention to compatibility matrix!!!
# - dpdk 17.02 -> pktgen 3.2.6
# - dpdk 17.05.2 -> pktgen 3.3.4 (ok compile)
#
#export RTE_VERSION="17.02"
#export PKTGEN_VERSION="3.2.6"
export RTE_VERSION="17.05.2"
export RTE_FOLDER="dpdk-stable-${RTE_VERSION}"
export RTE_TARGET="x86_64-native-linuxapp-gcc"
export RTE_SDK="${TMP_PATH}/${RTE_FOLDER}"
export PKTGEN_VERSION="3.3.4"
export DESTDIR="/opt/dpdk-${RTE_VERSION}"

# @info:    Parses and validates the CLI arguments
# @args:	Global Arguments $@

declare PARAM_A=''

sudo mkdir -p ${TMP_PATH}

# @info:	Prints out usage
function usage {
    echo
    echo "  ${0}: "
    echo "-------------------------------"
    echo
    echo "  info                  Displays system information (nic, cpu, ....)        "
    echo
    echo "  dpdk-install          Downloads and compiles dpdk   - http://www.dpdk.org/doc/guides/linux_gsg/index.html  "
    echo "  dpdk-setup            Runs dpdk setup               - http://www.dpdk.org/doc/guides/linux_gsg/quick_start.html"
    echo "  dpdk-helloworld       Builds dpdk helloworld        - http://www.dpdk.org/doc/guides/sample_app_ug/hello_world.html "
    echo "  dpdk-l2forward        Builds and runs l2fwd example - http://www.dpdk.org/doc/guides/sample_app_ug/l2_forward_real_virtual.html"
    echo
    echo "  pktgen-install        Downloads and builds dpdk pktgen - http://pktgen.readthedocs.io/en/latest/"
    echo "  pktgen-run            Runs pktgen"
    echo
    echo "  -h or --help          Opens this help menu"
    echo "  -v or --version       Prints the current version"
}

function parseCli(){
    if [[ "$#" -eq 0 ]]; then
        usage
    fi
    while [[ "$#" -gt 0 ]]; do
        key="$1"
        val="$2"
        case $key in
            
            info)
                echo " - List network"
                nmcli
                nmcli device show
                echo " List hardware cards"
                lspci | egrep -i --color 'network|ethernet'
                lshw -class network
                echo " - CPU info"
                lscpu
            ;;
            
            clean)
                echo " Clean huge pages"
                rm -f  /dev/hugepages/*
            ;;
            
            dpdk-install)
                # Download DPDK
                echo " - Build and install dpdk (RTE_SDK=${RTE_SDK} DESTDIR=${DESTDIR})"
                if [ ! -d "${RTE_SDK}" ]; then
                    cd ${TMP_PATH}
                    curl -O http://fast.dpdk.org/rel/dpdk-${RTE_VERSION}.tar.xz
                    tar xvf dpdk-${RTE_VERSION}.tar.xz
                fi
                cd ${RTE_SDK}
                mkdir -p ${DESTDIR}
                make install T=${RTE_TARGET} DESTDIR=${DESTDIR}
            ;;
            
            dpdk-setup)
                cd ${RTE_SDK}
                echo " - Start dpdk-setup.sh"
                source ${RTE_SDK}/usertools/dpdk-setup.sh
            ;;
            
            dpdk-helloworld)
                echo " - Compile DPDK helloworld"
                cd ${RTE_SDK}/examples/helloworld
                make
                cd ${RTE_SDK}/examples/helloworld/helloworld/x86_64-native-linuxapp-gcc/app
                ./helloworld
            ;;
            
            dpdk-l2forward)
                echo " - Compile dpdk-l2forward"
                dpdkInit
                cd ${BASE_PATH}/dpdk/l2fwd
                make clean
                make
                # attach l2forward to port 1 (port mask 0x2) -p 0x3
                ${BASE_PATH}/dpdk/l2fwd/build/app/l2fwd --file-prefix l2forward  --log-level=8 --socket-mem 512 -n 4 -- -q 8 -p 0x3 --mac-updating
            ;;
            
            pktgen-install)
                printenv |sort
                if [ ! -d "${TMP_PATH}/pktgen-${PKTGEN_VERSION}" ]; then
                    cd ${TMP_PATH}
                    curl -O http://dpdk.org/browse/apps/pktgen-dpdk/snapshot/pktgen-${PKTGEN_VERSION}.tar.xz
                    tar xvf pktgen-${PKTGEN_VERSION}.tar.xz
                fi
                cd ${TMP_PATH}/pktgen-${PKTGEN_VERSION}
                pwd
                make realclean
                make
            ;;
            dpdk-init)
                dpdkInit
            ;;
            pktgen-run)
                dpdkInit
                cd ${TMP_PATH}/pktgen-${PKTGEN_VERSION}
                ${TMP_PATH}/pktgen-${PKTGEN_VERSION}/app/x86_64-native-linuxapp-gcc/pktgen \
                --file-prefix pktgen  -n 1 --log-level=8 --socket-mem 256 \
                -- -P -m [1].0,[2].1
                #-f ${TMP_PATH}/../pktgen/l2fwd.lua
                reset
            ;;
            
            
            
            -v | --version) echo "Version: ${VERSION}" exit 0 ;;
            -h | --help | *) usage; exit 0 ;;
        esac
        shift
    done
    
}






function dpdkInit {
    # Set huge pages
    grep -s '/mnt/huge' /proc/mounts > /dev/null  && ans=0 || ans=$?
    if [ $ans -ne 0 ] ; then
        sudo -u root bash -c "echo 1024 > /sys/devices/system/node/node0/hugepages/hugepages-2048kB/nr_hugepages"
        sudo -u root bash -c "mkdir -p /mnt/huge && mount -t hugetlbfs nodev /mnt/huge"
    fi
    
    echo " - Loading DPDK UIO module"
    sudo modprobe uio
    /sbin/lsmod | grep -s igb_uio > /dev/null  && ans=0 || ans=$?
    if [ $ans -ne 0 ] ; then
        sudo /sbin/insmod $RTE_SDK/$RTE_TARGET/kmod/igb_uio.ko
    fi
    
    echo " - Disabled eth1 and eth2 network cards"
    sudo /sbin/ifdown eth1
    sudo /sbin/ifdown eth2
    echo " - Attach eth1 and eth2 network cards to UIO"
    sudo ${RTE_SDK}/usertools/dpdk-devbind.py -b igb_uio 0000:00:08.0 && echo "PCI: 0000:00:08.0 - Attached OK"
    sudo ${RTE_SDK}/usertools/dpdk-devbind.py -b igb_uio 0000:00:09.0 && echo "PCI: 0000:00:09.0 - Attached OK"
}

parseCli "$@"
