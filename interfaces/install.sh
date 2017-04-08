#!/bin/bash

HFRDIR="/etc/hfr"

# Create hfr directory
if [ ! -d "$HFRDIR" ] 
then
    echo "Creating HFR directory: $HFRDIR"
    mkdir "$HFRDIR"
    echo
fi

# copy scripts to the hfr directory
echo "Copying HFR scripts to $HFRDIR"
cp -va ifup-wait.sh lan_settings.sh setifacesv3.sh "$HFRDIR"
echo

# copy systemd services to /etc/systemd/system
echo "Copying systemd HFR services to /etc/systemd/system"
cp -va hfr-networking.service ifup-wait-all-auto.service /etc/systemd/system
echo

# reload systemd dependencies
echo "Reloading systemd daemon"
systemctl daemon-reload
echo
