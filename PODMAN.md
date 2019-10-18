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

# ceph-rpm
cp .env.podman.ceph-rpm ceph-rpm.env

mkdir -p cluster/ceph-rpm

sudo podman run --rm -d -v "$PWD"/docker/ceph:/docker:z \
    -v "$PWD"/cluster/ceph-rpm:/ceph/build/ceph:z \
    --env-file=ceph-rpm.env \
    --name=ceph-rpm --network=host --hostname=ceph-rpm -p 11000:11000 \
    --entrypoint /docker/rpm/entrypoint.sh \
    docker.io/rhcsdashboard/ceph-rpm:centos7 /docker/start.sh
```

* Run E2E tests:
```
sudo podman run --rm -v "$PWD"/../ceph/src:/ceph/src:z \
    -e BASE_URL=http://localhost:11000 \
    --name=e2e --network=host \
    docker.io/rhcsdashboard/e2e:nautilus
```
