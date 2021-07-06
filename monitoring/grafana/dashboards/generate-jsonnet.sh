#!/usr/bin/env bash

set -e
BASEDIR=$(dirname "$0")

for file in $BASEDIR/jsonnet/*; do
    name=$(basename $file)
    jsonnet $file > $BASEDIR/${name%.jsonnet}.json
done
