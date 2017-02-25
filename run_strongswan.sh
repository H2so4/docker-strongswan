#!/bin/bash

sysctl -w net.ipv4.conf.all.rp_filter=2

iptables --table nat --append POSTROUTING --jump MASQUERADE
echo 1 > /proc/sys/net/ipv4/ip_forward
for each in /proc/sys/net/ipv4/conf/*
do
	echo 0 > $each/accept_redirects
	echo 0 > $each/send_redirects
done

echo "Starting XL2TPD process..."
mkdir -p /var/run/xl2tpd
/usr/sbin/xl2tpd -c /etc/xl2tpd/xl2tpd.conf

ipsec start --nofork\
