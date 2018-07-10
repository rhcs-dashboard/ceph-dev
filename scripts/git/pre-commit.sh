#!/bin/bash

set -e

readonly TS_FILES=($(git diff --cached --name-only --diff-filter=ACMRTUXB | grep -E "*\.ts$"))
#echo "${#TS_FILES[@]}"

if [[ 0 < ${#TS_FILES[@]} ]]; then
    cd src/pybind/mgr/dashboard/frontend

    echo 'Running TypeScript checks...'

    ng lint

    echo 'Running Frontend unit tests...'

    ./node_modules/jest/bin/jest.js
fi

echo 'Pre-commit checks passed! Congratulations!'
