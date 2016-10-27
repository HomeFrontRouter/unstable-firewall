#!/bin/bash

#NET_BYTES="$(shuf -i 0-254 -n1).$(shuf -i 0-254 -n1)"
NET_BYTES="20.30"

LAN_IP="10.${NET_BYTES}.1"
LAN_MASK="24"
LAN_BRD="10.${NET_BYTES}.255"
LAN_MTU="1500"
