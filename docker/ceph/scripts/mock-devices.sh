#!/bin/bash

set -e

"$CEPH_BIN"/ceph mgr module enable test_orchestrator
"$CEPH_BIN"/ceph orch set backend test_orchestrator
"$CEPH_BIN"/ceph test_orchestrator load_data -i /docker/scripts/dummy_devices.json
