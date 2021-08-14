#!/bin/sh

KEYS=$(find /etc/ssh -name 'ssh_host_*_key')
[ -z "$KEYS" ] && ssh-keygen -A >/dev/null

cat /etc/ssh/sshd_config.in > /tmp/sshd_config
[ "x${ONLY_SFTP:-yes}" = "xno" ] || cat >> /tmp/sshd_config << EOF

AllowTcpForwarding no
ForceCommand internal-sftp
ChrootDirectory %h
EOF

exec /usr/sbin/sshd -D -e -f /tmp/sshd_config

