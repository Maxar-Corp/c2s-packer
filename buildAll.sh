#!/bin/bash
basepath=`pwd`

cd src/github.com/kardianos/govendor
go build
cp ./govendor ../../../../bin
cd ../../mitchellh/gox
go build
cd ../../hashicorp/packer
make standalone
cp ${basepath}/src/github.com/hashicorp/packer/pkg/linux_amd64/packer ${basepath}/bin
