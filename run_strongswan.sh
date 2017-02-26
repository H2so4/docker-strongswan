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

# Strongswan Configuration
cp ./ipsec.conf /etc/ipsec.conf
cp ./strongswan.conf /etc/strongswan.conf

# XL2TPD Configuration
cp ./xl2tpd.conf /etc/xl2tpd/xl2tpd.conf
cp ./options.xl2tpd /etc/ppp/options.xl2tpd

cp ./run.sh /run.sh
cp ./vpn_adduser /usr/local/bin/vpn_adduser
cp ./vpn_deluser /usr/local/bin/vpn_deluser
cp ./vpn_setpsk /usr/local/bin/vpn_setpsk
cp ./vpn_unsetpsk /usr/local/bin/vpn_unsetpsk
cp ./vpn_apply /usr/local/bin/vpn_apply
ipsec start --nofork\
