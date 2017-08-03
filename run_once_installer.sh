#!/bin/bash
#--------------------------------------------------
# This script copies the files into place.
#--------------------------------------------------

# Add packages
#apt-get install sudo, tcpdump, unionfs-fuse, bind9
apt-get install sudo tcpdump dnsmasq bridge-tools


# Setup the VLANs.
# Not applicable for zotac. Pablo Tue Jul 12 16:51:39 CDT 2016
#cp ./installer_files/swconfig /etc/network/if-pre-up.d/swconfig


# Setup the interfaces
mv /etc/network/interfaces /etc/network/interfaces.old  # save original
cp ./files_templates/interfaces /etc/network/interfaces


# DNSmasq setup
#mkdir /etc/dnsmasq.d
mkdir /etc/dnsmasq
mv /etc/dnsmasq.conf /etc/dnsmasq.conf.old  # save original
cp ./files_templates/dnsmasq.conf /etc/.


# Create the admin user
#  -m = create a home dir
#  -r = create a system account, assign it a UID
#  -s = shell to assign
#  -p = set this MD5 crypted password: homefront

AHOME="/home/admin"    # admin home

useradd -m -r -s /bin/bash -p 'd6966216ca97a1f18179255911fc1e6f' admin
cp -Ru ./scripts/* "$AHOME/."   # copy all scripts
chown -Rcv admin "$AHOME"       # set permissions
chmod -Rcv u+x "$AHOME"/*       # grant execution permissions


# SSH daemon stuff
mkdir .ssh
chmod 700 .ssh
touch .ssh/authorized_keys
chmod 600 .ssh/authorized_keys
# lockdown sshd (/etc/ssh/sshd) and restart it
# ListenAddress 192.168.13.5
# PermitRootLogin no
# PasswordAuthentication no
systemctl restart ssh.service

# TCPDUMP
#cp ./script/init.d/tcpdump.sh /etc/init.d
#chmod u+x /etc/init.d/tcpdump.sh


#
# systemd services
#

# Copy systemd services to /etc/systemd/system
cp ./systemd/* /etc/systemd/system/

# Reload systemd dependencies
systemctl daemon-reload


#
# Set LAN segment randomly
#

# Example using command shuf
#NET_BYTES="$(shuf -i 0-254 -n1).$(shuf -i 0-254 -n1)"

# Faster using built-in RANDOM
NET_BYTES="$(($RANDOM % 256)).$(($RANDOM % 256))"

cat <<EOT > ./LAN_SETTINGS
#
# LAN interface settings.
# Set at installation time: $(date +%F_%T)"
#
export LAN_IP="10.${NET_BYTES}.1"
export LAN_MASK="24"
export LAN_BRD="10.${NET_BYTES}.255"
export LAN_MTU="1500"
EOT

exit 0
