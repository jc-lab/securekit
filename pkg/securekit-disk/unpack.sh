#!/bin/bash

docker build --tag=securekit-mount-build .

mkdir -p $PWD/out/tmp/
docker save securekit-mount-build > $PWD/out/tmp/exported.tar
(cd $PWD/out/tmp/ && tar xf exported.tar)
(cd $PWD/out && for name in $(find tmp -type f -name "layer.tar"); do tar xf $name; done)



