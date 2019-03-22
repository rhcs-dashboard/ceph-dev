#!/bin/bash

set -e

ln -s /ceph/venv/bin/node /usr/local/bin/node \
    && ln -s /ceph/venv/bin/npm /usr/local/bin/npm \
    && ln -s /ceph/venv/bin/npx /usr/local/bin/npx

exec "$@"
