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
IFACES=( 'eth0' 'eth1' )    # ZOTAC interfaces
INTERFACE_TEMPLATE="./interfaces.template"    # time for a /etc/hfr ?

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
        log "  $iface set as LAN interface."
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

# create a new interfaces file using template
# note that the LAN network (10.0.0.0) it is an example as this will be
# setup using another script.
log "setting up a new interfaces file"
log
log "new /etc/network/interfaces -----------------------------"

sed 's/$WAN/'"$WAN"'/;s/$LAN/'"$LAN"'/' "$INTERFACE_TEMPLATE" | \
    tee /etc/network/interfaces | grep -v -E '^#|^$'

log "---------------------------------------------------------"

log "restarting networking: systemctl restart networking.service"
systemctl restart networking.service

log "done."
