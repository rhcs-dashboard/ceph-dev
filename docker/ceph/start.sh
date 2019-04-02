#!/bin/bash

set -e

source /docker/set-start-env.sh
/docker/start-ceph.sh

exec /docker/start-web-server.sh
