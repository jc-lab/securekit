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
