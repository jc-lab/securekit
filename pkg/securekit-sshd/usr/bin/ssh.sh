#!/bin/sh

KEYS=$(find /etc/ssh -name 'ssh_host_*_key')
[ -z "$KEYS" ] && ssh-keygen -A >/dev/null

cat /etc/ssh/sshd_config.in > /tmp/sshd_config
[ "x${ONLY_SFTP:-yes}" = "xno" ] || echo -n $'\nForceCommand internal-sftp\nChrootDirectory %h\n' >> /tmp/sshd_config

exec /usr/sbin/sshd -D -e -f /tmp/sshd_config

