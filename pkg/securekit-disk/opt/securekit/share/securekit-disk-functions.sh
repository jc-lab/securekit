function info() {
    echo "$*" | tee /dev/kmsg
}

function info_execute() {
    stderr_file=$(mktemp)
    echo "execute: $@" > /dev/kmsg
    (exec "$@") | tee /dev/kmsg 2>${stderr_file}
    rc=${PIPESTATUS[0]}
    [ -s ${stderr_file} ] && cat ${stderr_file} | tee /dev/kmsg >/dev/stderr
    rm ${stderr_file}
    return $rc
}

function info_func() {
    stderr_file=$(mktemp)
    echo "func: $@" > /dev/kmsg
    ("$@") | tee /dev/kmsg 2>${stderr_file}
    rc=${PIPESTATUS[0]}
    [ -s ${stderr_file} ] && cat ${stderr_file} | tee /dev/kmsg >/dev/stderr
    rm ${stderr_file}
    return $rc
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

function interactive_ready() {
    info "Ready interactive..."
    for tty_name in $(cat /sys/class/tty/console/active); do
        setsid /bin/bash -c "su manager <> /dev/${tty_name}>&0 2>&1" &
    done
    until [ -f /tmp/remote-tty.txt ]; do
        sleep 0.5
    done
    tty_dev=$(cat /tmp/remote-tty.txt)
    info "Start interactive on ${tty_dev}"
    sleep 0.5
}

function interactive_execute() {
    local tty_dev=$(cat /tmp/remote-tty.txt)
    (exec "$@" <> ${tty_dev}>&0 2>&1)
}
