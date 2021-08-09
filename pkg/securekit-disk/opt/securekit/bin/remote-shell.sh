#!/bin/bash

current_tty=$(tty)
echo "***** SECUREKIT INTERACTIVE MODE (${current_tty}) *****"

read -n 1 -r -s -p $'Press enter to continue...'
echo ""

echo ${current_tty} > /tmp/remote-tty.txt

while [ 1 ]; do
    sleep 1
done

exit 0
