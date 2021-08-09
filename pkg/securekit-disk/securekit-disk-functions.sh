function info() {
    echo "$*" | tee /dev/kmsg
    >&2 echo "$*"
}

function info_execute() {
    exec "$@" | tee /dev/kmsg
}

function find_volume_by_file() {
    local target_file_globpat=$1
    local exclude_device=$2
    local dev_path
    local dev_fs
    local dev_name
    local mount_path
    local found
    local rc

    while read blkline; do
        dev_path=$(echo $blkline | cut -d':' -f1)
        dev_fs=""
        [[ "$blkline" =~ TYPE=\"([^ ]+)\" ]] && dev_fs="${BASH_REMATCH[1]}"
        
        dev_name=${dev_path#/dev/}
        mount_path=/media/temp-${dev_name}
        mount_path=$mount_path
        mkdir -p ${mount_path}
        mount ${dev_path} $mount_path 2>/dev/null
        rc=$?
        
        if [ $rc -eq 0 ]; then
            >&2 echo "mount success = ${dev_path} => ${mount_path}"

            found=$(compgen -G "${mount_path}/${target_file_globpat}")
            rc=$?

            if [ $rc -eq 0 ]; then
                printf "${mount_path}\n${found}"
                return 0
            fi
            
            umount ${mount_path}
        fi

        rmdir ${mount_path}
    done <<< "$(blkid | egrep -v '/(loop|ram|fd|md|nbd)' | grep -v ${exclude_device})"

    return 1
}

function start_sshd() {
    #echo -n $"#!/bin/bash\necho hello world\nid\ntty\nsleep 100\nexit 1" > /tmp/xx1.sh
    #chmod +x /tmp/xx1.sh
    # info_execute setsid -w agetty -a root -L 38400 ttyS0 vt100 2>/tmp/xx
    #info_execute setsid -w agetty -a root -l /tmp/xx1.sh -L 38400 ttyS0 vt100 2>/tmp/xx
    setsid sh -c 'exec /bin/bash <> /dev/ttyS0 >&0 2>&1' 2>/tmp/xx
    #setsid -w agetty -L 38400 ttyS0 vt100 sh -c "echo Hello World" 2>/tmp/xx
    info_execute cat /tmp/xx
    sleep 10
    exit 1

    mkdir -p /run/sshd
    info "Network Informations: "
    info_execute ifconfig
    info "Start SSH"
    info_execute ssh-keygen -A
    info_execute cat /manager_authorized_keys | tee /home/manager/.ssh/authorized_keys 2>>/tmp/a1
    chmod 400 /home/manager/.ssh/authorized_keys
    chown manager:manager -R /home/manager/.ssh/
    /usr/sbin/sshd

    info "SSH Host Keys:"
    for name in $(find /etc/ssh/ -type f -name "ssh_host*key.pub"); do info_execute ssh-keygen -l -f $name; done
    
    while [ 1 ]; do
        echo "Waiting for attach ssh"
        until [ -f /tmp/remote-tty.txt ]; do
            sleep 0.5
        done
        sleep 0.5
        attached_tty=$(cat /tmp/remote-tty.txt)
        rm /tmp/remote-tty.txt
        info "attached_tty: ${attached_tty}"
        echo -n "HELLO WORLD: " > ${attached_tty}
        read -r line < ${attached_tty}
        info "RESPONSE: ${line}"
    done
}
