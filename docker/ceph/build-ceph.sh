#!/bin/bash

set -e

./install-deps.sh

rm -rf build

./do_cmake.sh

cd build

ccache make -j $(nproc --ignore=2)
