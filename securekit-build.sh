#!/bin/bash

build_dir=.
conf_file=

# linuxkit build [options] <file>[.yml] | -

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

function run() {
  set -ex
  
  # linuxkit build -dir "$build_dir" -format "kernel+initrd" $conf_file.yml
  docker buildx build --build-arg "IMAGE_NAME=$name" --output type=local,dest=${build_dir}/ --file ${script_dir}/efi.Dockerfile .
}

run "$@"






