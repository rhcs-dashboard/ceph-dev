#!/bin/bash

set -e

cd /ceph/build

bin/ceph mgr module disable dashboard
bin/ceph mgr module enable dashboard --force
