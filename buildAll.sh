#!/bin/bash
cd src/github.com/kardianos/govendor
go build
cd ../../mitchellh/gox
go build
cd ../../hashicorp/packer
make standalone
