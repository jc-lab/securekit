#!/bin/sh

PREFIX=$1

mkdir -p ${PREFIX}/etc/ssh

KEYS=$(find ${PREFIX}/etc/ssh -name 'ssh_host_*_key')
[ -z "$KEYS" ] && ssh-keygen -A -f ${PREFIX}/

if [ -n "${PREFIX}" ]; then
    if [ ! -e "${PREFIX}/etc/ssh/sshd_config.in" ]; then
        cp /etc/ssh/sshd_config.in ${PREFIX}/etc/ssh/sshd_config.in
    fi
fi

exit 0
