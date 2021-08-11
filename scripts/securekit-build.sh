#!/bin/bash

build_dir=.
conf_file=

while [ $# -gt 0 ]; do
  case "$1" in
    -dir)
      shift
      build_dir=$1
      ;;
    -size)
      shift
      build_size=$1
      ;;
    *)
      conf_file=$1
  esac
  shift
done

name=$conf_file

script_dir=$(dirname ${BASH_SOURCE})

function download_linux_efi_stub() {
  set -ex
  local filepath=$1
  local filehash=083ea2d7b5f7ff8a289eb9fd8dba86eabfad075ae025df1c4bb475e4890cdbbf
  curl -L -o ${filepath} "https://github.com/jc-lab/systemd-boot-efi/releases/download/v249-jclab03/linuxx64.efi.stub"
  echo "${filehash}  ${filepath}" | sha256sum -c
}

function run() {
  set -ex
  
  local linux_efi_stub=${build_dir}/linuxx64.efi.stub
  local unsigned_efi=$(mktemp).efi
  local signed_efi=${build_dir}/${name}-linux.efi
  
  download_linux_efi_stub ${linux_efi_stub}
  
  # build linuxkit kernel+initrd
  linuxkit build -dir "$build_dir" -format "kernel+initrd" $conf_file.yml
  
  # build single efi image
  objcopy \
    --add-section .cmdline="${build_dir}/${name}-cmdline" --change-section-vma .cmdline=0x30000 \
    --add-section .linux="${build_dir}/${name}-kernel" --change-section-vma .linux=0x2000000 \
    --add-section .initrd="${build_dir}/${name}-initrd.img" --change-section-vma .initrd=0x3000000 \
    "${linux_efi_stub}" "${unsigned_efi}"
  
  ${script_dir}/efi-sign.sh "${unsigned_efi}" "${signed_efi}"
    
  # build iso
  docker buildx build --build-arg "IMAGE_NAME=${name}" --output type=local,dest=${build_dir}/ --file ${script_dir}/efi-iso.Dockerfile ${build_dir}
}

run "$@"


