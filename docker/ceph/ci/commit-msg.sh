#!/usr/bin/env bash

set -e

echo "Running commit-msg hook..."

readonly BRANCH=$(git rev-parse --abbrev-ref HEAD)

if [[ "$BRANCH" == ceph-*-rhel-patches ]]; then
    grep "^Resolves: rhbz#[0-9]\+" "$1" || {
        echo >&2 "Error: Missing 'Resolves: rhbz#<bz_number>' in commit message"
        exit 1
    }
fi
