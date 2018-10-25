#!/bin/bash

set -e

/docker/start-ceph.sh

/opt/node_exporter/node_exporter &

exec /docker/start-web-server.sh
