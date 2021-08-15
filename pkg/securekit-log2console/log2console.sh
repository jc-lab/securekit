#!/bin/bash

function ttys() {
    cat /sys/class/tty/console/active | sed -e "s/ /\n/g" | sed -e "s:^:/dev/:g"
}

cat /var/log/onboot/*.log | tee $(ttys) > /dev/null

n=100
while [ 1 ]; do
    sleep 1
    tail -n $n -f /var/log/*.log | tee $(ttys) > /dev/null
    n=1
done

