#!/bin/bash

set -e

/docker/start-ceph.sh

printf "\n*********\nAll done.\n*********\n"

# Keep container running
exec tail -f /dev/null
