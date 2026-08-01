#!/bin/bash
set -e

echo "=== CephaloBox Orchestrator Wrapper Started ==="

# Ensure standard binaries and your custom build path are fully accessible in PATH
export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/ceph/build/bin

# Execute the main Python automation script
python3 -u /usr/local/bin/cephalobox.py
/bin/bash /usr/local/bin/osd.sh

echo "=== CephaloBox Orchestrator Finished Successfully ==="

