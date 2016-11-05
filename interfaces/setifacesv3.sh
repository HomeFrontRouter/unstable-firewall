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
    echo "$(date '+%b %d %T') $1" | tee -a "./hfr_network.log"
}

# global variables
INTERNET_SITE="8.8.8.8" # address to ping

# obtaining setings for LAN network: $LAN_IP, $LAN_MASK, $LAN_BRD, and $LAN_MTU
source ./lan_settings.sh

#IFACES=( 'eth0' 'eth1' )    # ZOTAC interfaces

# get list of available interfaces
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
    log "Probing ${iface}:"

    # temporary files for lease and pid
    lease_file="/run/dhclient.lease.$iface"
    pid_file="/run/dhclient.pid.$iface"

    # remove old files if they exist
    rm -vf "$lease_file"
    rm -vf "$pid_file"

    # just a query to a temp file
    dhclient -nw -pf "$pid_file" -lf "$lease_file" "$iface" &
    sleep 4     # wait for request to be answered

    # the offer will be on the lease file
    lease_line="$(grep fixed-address "$lease_file" 2> /dev/null)"
    if [ $? -eq 0 ]
    then
        # get leased address
        tmp="${lease_line##* }"
        lease="${tmp%;}"

        log "  DHCP offer received. Leasing: $lease"

        # check if previous interface had access to the Internet
        if [[ ! -n $WAN ]]
        then
            # no access to the internet yet

            # test if this interface has access to the Internet
            log "  testing WAN/Internet access: pinging $INTERNET_SITE"
            if ping -c3 "$INTERNET_SITE" > /dev/null 2>&1
            then
                log "  success: $INTERNET_SITE is accessible."
                log "  $iface set as WAN interface."
                log "  $lease will be kept."

                WAN="$iface"
            else
                log "  $INTERNET_SITE is NOT accessible."
                log "  $iface set as LAN interface."
                log "  $lease will be kept anyway."

                LAN="$iface"
            fi
        else
            # previous interface had access to the Internet
            log "  already have access to the Internet."
            log "  $iface set as LAN interface."
            log "  $lease will be kept anyway."

            LAN="$iface"
        fi
    else
        # stop the background process
        #dhclient -x -pf "$pid_file" # this does not work
        kill -9 "$(cat $pid_file)"

        log "  No DHCP offer received."
        log "  $iface will be setup as a LAN interface."
        log "  setting $iface as ${LAN_IP}/${LAN_MASK}"

        # set LAN ip address
        ip addr add "${LAN_IP}/${LAN_MASK}" broadcast "${LAN_BRD}" dev "${iface}"
        ip link set mtu "${LAN_MTU}" dev "${iface}"
        LAN="$iface"
    fi

done

# in case no interface received an DHCP offer
if [[ ! -n $WAN ]]
then
    log "ERROR: no access to the Internet."
    log "exiting..."
    exit 1
else
    log "done."
    exit 0
fi
