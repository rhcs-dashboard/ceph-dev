# RHCS Dashboard Dev. Env.

## Installation

* Clone Ceph:
```
git clone git@github.com:ceph/ceph.git
```

* If it doesn't exist, create a local directory for **ccache**:
```
mkdir -p ~/.ccache
```

* Clone rhcs-dashboard/ceph-dev:
```
git clone git@github.com:rhcs-dashboard/ceph-dev.git
cd ceph-dev
```

* Install [Docker Compose](https://docs.docker.com/compose/install/). If your OS is Fedora, run this:
```
sudo bash ./scripts/docker/install-docker-compose-fedora.sh
```

* Create *.env* file from template and set values:
```
cp .env.example .env

HOST_CCACHE_DIR=/path/to/your/local/.ccache/dir

CEPH_REPO_DIR=/path/to/your/local/ceph/repo
# Optional: a custom build directory other than default one ($CEPH_REPO_DIR/build)
CEPH_CUSTOM_BUILD_DIR=
# Set 5200 if you want to access the dashboard proxy at http://localhost:5200
CEPH_PROXY_HOST_PORT=4200
# Set 11001 if you want to access the dashboard at https://localhost:11001
CEPH_HOST_PORT=11000

# default: 3000
GRAFANA_HOST_PORT=3000
# default: 9090
PROMETHEUS_HOST_PORT=9090
# default: 9100
NODE_EXPORTER_HOST_PORT=9100
```

* Download docker images:
```
docker-compose pull
```

* Optionally, set up git pre-commit hook:
```
docker-compose run --rm -e HOST_PWD=$PWD ceph /docker/ci/pre-commit-setup.sh
```

## Usage

* Build Ceph:
```
docker-compose run --rm ceph /docker/build-ceph.sh
```

* Start ceph + grafana + prometheus + node-exporter:
```
docker-compose up -d

# Only ceph:
docker-compose up -d ceph
```

* Display ceph container logs:
```
docker-compose logs -f ceph
```

* Access proxied dashboard:

When you see in the logs something like this:
```
ceph    | ℹ ｢wdm｣: Compiled successfully.
```

http://localhost:$CEPH_PROXY_HOST_PORT

* Access dashboard:

https://localhost:$CEPH_HOST_PORT

* Restart dashboard module:
```
docker-compose exec ceph /docker/restart-dashboard.sh
```

* Run frontend E2E tests:
```
docker-compose exec ceph /docker/e2e/run-frontend-e2e-tests.sh
```

* Stop all:
```
docker-compose down
```

* Rebuild not proxied dashboard frontend:
```
docker-compose run --rm ceph /docker/build-dashboard-frontend.sh
```

* Run sanity checks:
```
docker-compose run --rm ceph /docker/ci/run-sanity-checks.sh
```

## API tests based on Teuthology (Ceph integration test framework)

* Install Teuthology in a temporary folder and start a cluster:
```
docker-compose run --rm ceph bash
cd src/pybind/mgr/dashboard
source ./run-backend-api-tests.sh
```

* Run tests (example: only dashboard tests):
```
run_teuthology_tests tasks.mgr.dashboard.test_dashboard.DashboardTest
cleanup_teuthology
```

## Grafana

If you have started grafana, you can access it at:
http://localhost:$GRAFANA_HOST_PORT/login

## Prometheus

If you have started prometheus, you can access it at:
http://localhost:$PROMETHEUS_HOST_PORT

## Build and push an image to docker registry:

If you want to update an image, you'll have to edit image's Dockerfile and then:

* Build image (example: rhcsdashboard/ceph):
```
docker build -t {imageName} {/path/to/DockerfileDirectory}
docker build -t rhcsdashboard/ceph ./docker/ceph
```

* Log in to rhcs-dashboard docker registry and push image (example: rhcsdashboard/ceph):
```
docker login -u rhcsdashboard
docker push {imageName}
docker push rhcsdashboard/ceph
```

## Start Ceph 2 (useful for parallel development)

* Set appropriate values in *.env*:
```
CEPH2_REPO_DIR=/path/to/your/local/ceph2
CEPH2_CUSTOM_BUILD_DIR=
# default: 4202
CEPH2_PROXY_HOST_PORT=4202
# default: 11002
CEPH2_HOST_PORT=11002
```

* Start ceph + ceph2:
```
docker-compose up -d --scale ceph2=1

# Only ceph2:
docker-compose up -d --scale ceph2=1 --scale ceph=0
```

## Start RHCS 3.2 RPM version

* Set appropriate values in *.env* (you have to be logged into private registry):
```
RHCS3_2_IMAGE=docker-registry.engineering.redhat.com/ceph-dashboard/rhcs3.2
# default: 11032
RHCS3_2_HOST_PORT=11032
```

* Start ceph + rhcs3.2:
```
docker-compose up -d --scale rhcs3.2=1

# Only rhcs3.2:
docker-compose up -d --scale rhcs3.2=1 --scale ceph=0
```
