# DPDK playground

Vagrant box and examples to learn and test Data Plane Development Kit DPDK http://www.dpdk.org

DPDK is a set of libraries and drivers for fast packet processing and runs on any
processors in Linux user space.

- [Overview](#overview)
- [Run](#run)
  - [Build DPDK](#build-dpdk)
  - [Start l2fwd on receiver](#start-l2fwd-on-receiver)
  - [Start pktgen on sender](#start-pktgen-on-sender)
- [Packet drops](#packet-drops)
- [Further Reading](#further-reading)
- [License](#license)

## Overview

This project started as an experiment on kernel bypass to reduce udp network latency

This repo contains:

- Script `run.sh` to simplify basic operations
- vagrant script to boot two virtual box (with 3 nic each)
- VM sender runs pktgen to generate network traffic
- VM receiver runs l2fwd dpdk example to fwd packet back to sender

Each VM has 3 network cards, one is for ssh access and two to test dpdk, see [Vagrantfile](./Vagrantfile)

Use two different vbox host-only-network name: vboxnet0 and vboxnet1 to isolate traffic and avoid multi cast on different cards

```ascii
--------- SEND ----------------------                   ------ RECEIVER --------------------------
pktgen (port 0) | -> mac:080020000001 -> (vboxnet0) ->  mac:080020000003 -> | (port 0) L2 fwd back
pktgen (port 1) | <- mac:080020000002 <- (vboxnet1) <-  mac:080020000004 <- | (port 1) L2 fwd back
```

## Run

First run

- install `vagrant`
- install `vagrant-vbguest` plugin
- run `vagrant up`

Update

- upgrade vagrant box `vagrant box update --box 'centos/7'`
- upgrade plugin `vagrant plugin update`

### Build DPDK

Run ob both vms:

- run `sudo /vagrant/run.sh dpdk-install` build and install target x86_64-native-linuxapp-gcc
- run `sudo /vagrant/run.sh dpdk-setup` and select option [15] to  install IGB UIO kernel driver [info](http://dpdk.org/doc/guides/linux_gsg/linux_drivers.html#linux-gsg-binding-kernel)

### Start l2fwd on receiver

L2 forwards any RX packet to the adjacent port from the enabled portmask (eg. ports 1 and 2 forward into each other )

Docs <http://dpdk.org/doc/guides/sample_app_ug/l2_forward_real_virtual.html>


Execute on receiver

- run `vagrant ssh receiver`
- run `/vagrant/run.sh /vagrant/run.sh  dpdk-l2forward`

### Start pktgen on sender

In a terminal:

- `vagrant ssh sender`
- `sudo /vagrant/run.sh pktgen-install`
- `sudo /vagrant/run.sh pktgen-run`

Latency (in pktgen console)

- enable latency `enable 0,1 latency` (An L in flags line show LATENCY state)
- show latency `page latency`

In pktgen cli:

- set destination MAC address to receiver box `set 0 dst mac 0800:2000:0003`
- reduce packets sent:
  - reduce rate to 10% `set 0,1 rate 10`
  - OR set a fixed packets number `set 0,1 count 100`
- start packet sender on port 0 `start 0`
- after some times stop `stop 0`

If everything works packets flow from sender to receiver and come back.

## Packet drops

L2forward app on receiver reports around 50% of packets dropped. Why????
Because VMis slow to process packets and is sensible to context switch from host os

See this good pdf <http://etherealmind.com/wp-content/uploads/2017/01/X520_to_XL710_Tuning_The_Buffers.pdf>

In l2fwd/main.c enlarge dpdk buffers:

```c
#define NB_MBUF   16384

#define RTE_TEST_RX_DESC_DEFAULT 4096

#define RTE_TEST_TX_DESC_DEFAULT 4096

```

## Further Reading

- dpdk <http://dpdk.org/doc/guides/index.html>
- pktgen <http://pktgen.readthedocs.io/en/latest/index.html>
- exclude cpu from kernel <https://codywu2010.wordpress.com/2015/09/27/isolcpus-numactl-and-taskset>

## License

DPDK is an Open Source BSD licensed project.
