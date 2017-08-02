#!/bin/bash
for i in $(/sbin/ifquery --list --exclude lo --allow auto)
do
    INTERFACES="$INTERFACES$i "
done

[ -n "$INTERFACES" ] || exit 0

echo "INTERFACES: $INTERFACES"

while ! /sbin/ifquery --state $INTERFACES > /dev/null
do
    echo "ifquery is not ready. Sleeping 1 sec."
    sleep 1
done

echo "ifquery list interfaces as ready."

for link in $INTERFACES
do
    #echo "looping on $link"
    if [[ -e "/sys/class/net/$link" && -e "/sys/class/net/$link/operstate" ]]
    then
        while [ "$(cat /sys/class/net/$link/operstate)" != "up" ]
        do
            echo "Waiting for up state on $link"
            echo "Current state: $(cat /sys/class/net/$link/operstate)"
            echo "Sleeping 0.2"
            sleep 0.2
        done
    fi

    echo "$link is UP!"
    
done

exit 0
