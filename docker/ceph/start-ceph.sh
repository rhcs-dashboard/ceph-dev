#!/bin/bash

set -e

cd /ceph/build

RGW=1 ../src/vstart.sh -d -n
