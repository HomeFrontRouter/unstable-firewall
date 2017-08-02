#!/bin/bash
#
# seifaces.sh
# Probe interfaces for DHCP services, and setup the proper
# /etc/network/interfaces file.
#
# This file is part of HomeFrontRouter.

# Author: Pablo Piaggio (pabpia@gmail.com)
#
# Copyright (C) 2016 Pablo Piaggio, HomeFrontRouter project.

# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.


# log/echo function
# easy to change all output to a log if necessary
log()
{
    #echo "$1" > /path/to/log
    #echo "$1" | tee /path/to/log
    echo "$1"
}

# global variables
#IFACES=( 'eth0' 'eth1' )    # ZOTAC interfaces
IFACES=$(for iface in $(/sbin/ifquery --list --allow=hotplug)
        do
            link=${iface##:*}
            link=${link##.*}
            if [ -e "/sys/class/net/$link" ]
            then
                # link detection does not work unless we up the link
                ip link set "$iface" up || true
                if [ "$(cat /sys/class/net/$link/operstate)" = up ]
                then
                    echo "$iface"
                fi
            fi
        done)

# cicle over all interfaces
for iface in ${IFACES[@]}
do
    log "probing $iface ...."

    # temporary files for lease and pid
    lease_file="/tmp/dhclient.lease.$iface"
    pid_file="/tmp/dhclient.pid.$iface"

    # remove old files if they exist
    rm -f "$lease_file"
    rm -f "$pid_file"

    # just a query to a temp file
    dhclient -q -1 -sf /dev/null -lf "$lease_file" -pf "$pid_file" "$iface" &
    sleep 2     # wait for request to be answered

    # the offer will be on the lease file
    lease="$(grep fixed-address "$lease_file" > /dev/null 2>&1)"
    if [ $? -eq 0 ]
    then
        WAN="$iface"
        log "  DHCP offer received: $lease"
        log "  $iface set as WAN interface."
    else
        LAN="$iface"
        log "  No DHCP offer received."
        log "  $iface will be setup as a LAN interface."
    fi

    # stop the background process
    dhclient -x -pf "$pid_file"
done

# testing: is this necessary?
# killall dhclient

# in case no interface received an DHCP offer
if [[ ! -n $WAN ]]
then
    echo "ERROR: no DHCP server found."
    echo "exiting..."
    exit 1
fi

# obtaining setings for LAN network:
#   $LAN_IP
#   $LAN_MASK
#   $LAN_BRD
#   $LAN_MTU
source ./lan_settings.sh

log "---------------------------------------------------------"

# set up WAN interface manually
log "setting up $LAN as a LAN interface."

ip addr add "${LAN_IP}/${LAN_MASK}" broadcast "${LAN_BRD}" dev "${LAN}"  # set ip address
ip link set mtu "${LAN_MTU}" dev "${LAN}"         # set mtu

log "setting up $WAN as a WAN interface."
log "starting DHCP service on ${WAN}."
dhclient -v -pf "/run/dhclient.${WAN}.pid" -lf "/var/lib/dhcp/dhclient.${WAN}.leases" "$WAN"

log "done."
