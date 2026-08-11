#!/bin/bash
set -e

echo "=== CephaloBox Orchestrator Wrapper Started ==="

# to make sure env vars from host are available inside containers
if [ -f /proc/1/environ ]; then
    while IFS= read -r -d '' env_var; do
        if [[ "$env_var" == *=* ]]; then
            export "$env_var"
        fi
    done < /proc/1/environ
fi

export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/ceph/build/bin

# Execute the main Python automation script
python3 -u /usr/local/bin/cephalobox.py
/bin/bash /usr/local/bin/osd.sh

echo "=== CephaloBox Orchestrator Finished Successfully ==="

