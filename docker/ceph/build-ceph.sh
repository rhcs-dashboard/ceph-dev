#!/bin/bash

set -e

./install-deps.sh

rm -rf build

# Tricks to improve CCACHE hit ratio
export SOURCE_DATE_EPOCH=$(date -d 'today 00:00 UTC' +%s)
export BUILD_DATE=$(date --utc --date=@${SOURCE_DATE_EPOCH} +%Y-%m-%d)
export ARGS='-D ENABLE_GIT_VERSION=OFF'
export CCACHE_SLOPPINESS="time_macros"

./do_cmake.sh

cd build

ccache make -j $(nproc --ignore=2)
