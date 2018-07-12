#!/bin/bash

set -e

echo 'Running pre-commit hook...'

readonly TS_FILES=($(git diff --cached --name-only --diff-filter=ACMRTUXB "*.ts" | tr '\n' ' '))
echo "TS_FILES: ${#TS_FILES[@]}"
readonly SCSS_FILES=($(git diff --cached --name-only --diff-filter=ACMRTUXB "*.scss" | tr '\n' ' '))
echo "SCSS_FILES: ${#SCSS_FILES[@]}"

cd src/pybind/mgr/dashboard/frontend

if [[ ! -z "$TS_FILES" || ! -z "$SCSS_FILES" ]]; then
    echo 'Running Prettier...'
    npm run makePretty --staged

    if [[ ! -z "$TS_FILES" ]]; then
        echo 'Running TypeScript checks...'
        ng lint

        echo 'Running Frontend unit tests...'
        ./node_modules/jest/bin/jest.js
    fi
fi

echo 'Pre-commit hook successfully finished! Congratulations!'
