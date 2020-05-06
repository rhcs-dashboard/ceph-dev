# PODMAN Dev. Env.

## Installation

* Install **podman**:
```
dnf install podman
```

* Clone Ceph:
```
git clone git@github.com:ceph/ceph.git
```

* Clone rhcs-dashboard/ceph-dev:
```
git clone git@github.com:rhcs-dashboard/ceph-dev.git
```

## Usage

* Start cluster:
```
cd ceph-dev

cp .env.podman.ceph ceph.env

mkdir -p cluster/ceph

sudo podman run --rm -d -v "$PWD"/docker/ceph:/docker:z \
    -v "$PWD"/cluster/ceph:/ceph/build/ceph:z \
    --env-file=ceph.env \
    --name=ceph --network=host --hostname=ceph -p 11000:11000 \
    --entrypoint /docker/entrypoint.sh \
    docker.io/rhcsdashboard/ceph-rpm:master /docker/start.sh
```

* Run E2E tests:
```
sudo podman build -t docker.io/rhcsdashboard/e2e:nautilus \
    ./docker/ceph/e2e

sudo podman run --rm -v "$PWD"/../ceph/src:/ceph/src:z \
    -e BASE_URL=http://localhost:11000 \
    --name=e2e --network=host \
    docker.io/rhcsdashboard/e2e:nautilus
```
