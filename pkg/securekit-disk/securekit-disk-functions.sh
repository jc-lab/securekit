function find_volume_by_file() {
    local target_file_globpat=$1
    local dev_path
    local dev_fs
    local dev_name
    local mount_path
    local found
    local rc

    while read blkline; do
        dev_path=$(echo $blkline | cut -d':' -f1)
        dev_fs=$(echo $blkline | gawk 'match($0, "TYPE=\"([^ ]+)\"", a) { print a[1]}' | tr '[:upper:]' '[:lower:]')

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
    done <<< "$(blkid | egrep -v '/(loop|ram|fd|md|nbd)')"

    return 1
}
