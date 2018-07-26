#!/bin/bash

set -e

cd /ceph/build

rm -rf out dev

RGW=1 ../src/vstart.sh -d -n
