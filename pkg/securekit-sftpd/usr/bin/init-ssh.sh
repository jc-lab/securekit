#!/bin/sh

PREFIX=$1

mkdir -p ${PREFIX}/etc/ssh

KEYS=$(find ${PREFIX}/etc/ssh -name 'ssh_host_*_key')
[ -z "$KEYS" ] && ssh-keygen -A -f ${PREFIX}/

if [ -n "${PREFIX}" ]; then
    [ ! -e "${PREFIX}/etc/ssh/sshd_config" ] && cp /etc/ssh/sshd_config ${PREFIX}/etc/ssh/sshd_config
fi

exit 0
