#!/bin/sh

# we are a router
echo 1 > /proc/sys/net/ipv4/conf/all/forwarding
echo 1 > /proc/sys/net/ipv4/ip_forward


# ignore ICMP broadcast requests
/bin/echo "1" > /proc/sys/net/ipv4/icmp_echo_ignore_broadcasts
/bin/echo "1" > /proc/sys/net/ipv4/icmp_ignore_bogus_error_responses

/bin/echo "0" > /proc/sys/net/ipv4/conf/all/accept_source_route
/bin/echo "1" > /proc/sys/net/ipv4/conf/all/accept_redirects

# log packets arriving with addresses incompatible with the interface
/bin/echo "1" > /proc/sys/net/ipv4/conf/all/log_martians

#
# Defend against various attacks
#

# syn-flooding protection
iptables -N syn-flood
iptables -A INPUT -i $OUTSIDE_IF -p tcp --syn -j syn-flood
iptables -A syn-flood -m limit --limit 1/s --limit-burst 4 -j RETURN
iptables -A syn-flood -j DROP

# make sure NEW tcp connections are SYN packets
iptables -A INPUT -i $OUTSIDE_IF -p tcp ! --syn -m state --state NEW -j DROP

# JF
iptables -A FORWARD -i eth0.101 -s 192.168.13.0/255.255.255.0 -j ACCEPT
iptables -A FORWARD -i eth0.201 -d 192.168.13.0/255.255.255.0 -j ACCEPT
# iptables -t nat -A POSTROUTING -o eth0.201 -j MASQUERADE




exit 0
