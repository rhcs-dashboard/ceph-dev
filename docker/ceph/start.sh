#!/bin/bash

set -e

/docker/start-ceph.sh

exec /docker/start-web-server.sh
