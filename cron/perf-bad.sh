#!/bin/bash

sudo tc qdisc del dev eth0 root
sudo tc qdisc del dev eth1 root
sudo tc qdisc add dev eth0 root handle 1:0 tbf rate 100Mbit burst 1000M latency 5000ms
sudo tc qdisc add dev eth1 root handle 2:0 tbf rate 100Mbit burst 1000M latency 5000ms
sudo tc qdisc add dev eth0 parent 1:1 handle 10: netem delay 500ms 50ms loss 5
sudo tc qdisc add dev eth1 parent 2:1 handle 10: netem delay 500ms 50ms loss 5
