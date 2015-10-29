# This script copies the files into place.

# Add packages
# apt-get install sudo, tcpdump, unionfs-fuse, bind9
apt-get install sudo tcpdump dnsmasq bridge-tools

# Setup the VLANs
cp ./installer_files/swconfig /etc/network/if-pre-up.d/swconfig

# Setup the interfaces
cp ./installer_files/interfaces /etc/network/interfaces

# Bind setup
mkdir /etc/dnsmasq
cp ./installer_files/dnsmasq.conf /etc/.



# Create the admin user
#  -m = create a home dir
#  -r = create a system account, assign it a UID
#  -s = shell to assign
#  -p = set this MD5 crypted password: homefront
useradd -m -r -s /bin/bash -p 'd6966216ca97a1f18179255911fc1e6f' admin
mkdir /home/admin/firewall
cp installer.sh /home/admin/firewall/.
cp functions.sh /home/admin/firewall/.
cp -Ru rules.d /home/admin/firewall/.
chown -Rcv admin /home/admin
chmod -Rcv u+x /home/admin/firewall/ *.sh


# SSH daemon stuff
mkdir .ssh
chmod 700 .ssh
touch .ssh/authorized_keys
chmod 600 .ssh/authorized_keys
# lockdown sshd (/etc/ssh/sshd) and restart it
# ListenAddress 192.168.13.5
# PermitRootLogin no
# PasswordAuthentication no
service ssh restart



# Set the firewall to start automatically on boot
cp ./init.d/firewall.sh /etc/init.d
chmod u+x /etc/init.d/firewall.sh
update-rc.d firewall.sh defaults 12345 06

# set the iptables rules....
cp -rp ./rules.d /etc/init.d/.
#

# Add a default route only works AFTER the interface exists
# route add default gw 192.168.13.6
