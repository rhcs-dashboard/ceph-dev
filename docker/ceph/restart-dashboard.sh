#!/bin/bash

set -e

cd /ceph/build

bin/ceph mgr module disable dashboard

sleep 1

bin/ceph mgr module enable dashboard
