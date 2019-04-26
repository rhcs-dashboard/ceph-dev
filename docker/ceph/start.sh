#!/bin/bash

set -e

source /docker/set-start-env.sh

/docker/start-ceph.sh

if [[ "$FRONTEND_BUILD_REQUIRED" == 1 ]]; then
    # Start dev server
    if [[ "$DASHBOARD_DEV_SERVER" == 1 ]]; then
        /docker/set-dev-server-proxy.sh

        cd "$MGR_PYTHON_PATH"/dashboard/frontend

        npm run start &
    else
        cd "$MGR_PYTHON_PATH"/dashboard/frontend

        npm run build -- --watch &
    fi
fi

printf "*********\nAll done.\n*********"

# Keep container running
exec tail -f /dev/null
