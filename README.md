# DPDK playground

Vagrant box and examples to learn and test Data Plane Development Kit DPDK http://www.dpdk.org

DPDK is a set of libraries and drivers for fast packet processing and runs on any
processors in Linux userland.


## Background

This project started as an experiment on kernel bypass to reduce udp network latency

## Install

Before start, install `vagrant` and `vagrant-vbguest` plugin


## Usage

Basic example consists of:
- two virtual box (with 3 nic each)
- on sender box : pktgen running to generate network traffic
- on receiver: l2fwd dpdk example to fwd packet back to sender

Script `run.sh` provide shortcuts for basic operations

Bring up virtual boxes with `vagrant up`

## Start l2fwd on receiver

- `vagrant ssh receiver`
- `/vagrant/run.sh /vagrant/run.sh  dpdk-l2forward`

## Start pktgen on sender

In a terminal:

- `vagrant ssh sender`
- `/vagrant/run.sh pktgen-run`

In pktgen cli:
- set destination MAC address to receiver box `set 0 dst mac 0800:2000:0003`
- start packet sender on port 0 `start 0`
- after some times stop `stop 0`

If everything works packets flow from sender to receiver and come back. 


## Further Reading

- dpdk http://dpdk.org/doc/guides/index.html
- pktgen http://pktgen.readthedocs.io/en/latest/index.html
- exclude cpu from kernel https://codywu2010.wordpress.com/2015/09/27/isolcpus-numactl-and-taskset/


## License

DPDK is an Open Source BSD licensed project.
