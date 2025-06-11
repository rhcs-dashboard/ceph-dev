![Publish ceph images](https://github.com/rhcs-dashboard/ceph-dev/actions/workflows/main.yml/badge.svg?branch=main)

# RHCS Dashboard Dev. Env.

## Quick Install

1. Clone the Ceph repo (both `--depth 1 --single-branch` are optional flags but they'll dramatically reduce the amount of data transferred and stored):
    ```sh
    git clone --depth 1 --single-branch git@github.com:ceph/ceph.git
    ```
1. Clone this repo:
    ```sh
    git clone https://github.com/rhcs-dashboard/ceph-dev.git
    ```
1. Enter `ceph-dev` directory.
1. To install `docker` and `docker-compose`, if you're using:
   * Fedora: `sudo bash ./docker/scripts/install-docker-compose-fedora.sh`
   * CentOS/RHEL: `sudo bash ./docker/scripts/install-docker-compose-centos-rhel.sh`
   * Other OSes: please check [this](https://docs.docker.com/compose/install/). Additionally, please ensure that SELinux is running in permissive mode:
     ```bash
     setenforce 0
     sed -i -E 's/^SELINUX=enforcing$/SELINUX=permissive/' /etc/selinux/config
     ```
1. Use `.env.example` template for ceph-dev configuration: `cp .env.example .env`, edit `.env` and modify `CEPH_REPO_DIR=/path/to/...` to point to the directory where you cloned the Ceph repo (step #1)
1. Download the container images: `docker-compose pull`
1. Launch it (for a minimal Ceph-only deployment):
    ```
    docker-compose up -d ceph
    ```
    or  (for Ceph + monitoring stack):
    ```
    docker-compose up -d ceph grafana prometheus alertmanager node-exporter
    ```
1. Check how things are going with `docker-compose logs -f ceph`:
   * After a couple of minutes (aprox.) it'll finally print `All done`.
1. The dashboard will be available at: `https://127.0.0.1:11000` with credentials: `admin / admin`.

## Advanced Installation

* Clone Ceph:
```
git clone git@github.com:ceph/ceph.git
```

* Clone rhcs-dashboard/ceph-dev:
```
git clone git@github.com:rhcs-dashboard/ceph-dev.git
```

* In ceph-dev, create *.env* file from template and **set your local values**:
```
cd ceph-dev
cp .env.example .env
```

* Install [Docker Compose](https://docs.docker.com/compose/install/) by running the following, depending on your OS:
```
# Fedora:
sudo bash ./docker/scripts/install-docker-compose-fedora.sh

# CentOS 7 / RHEL 7:
sudo bash ./docker/scripts/install-docker-compose-centos-rhel.sh
```

If you ran the above script, then you can run *docker* and *docker-compose* without *sudo* if you log out and log in.

* Download docker images:
```
docker-compose pull
```

* Optionally, set up git pre-commit hook:
```
docker-compose run --rm -e HOST_PWD=$PWD ceph /docker/ci/pre-commit-setup.sh
```

## Usage

You don't need to build ceph if you've set ```CEPH_IMAGE=rhcsdashboard/ceph-rpm:...``` container image (the default).

### Start ceph + dashboard feature services:
```
docker-compose up -d

# Only ceph:
docker-compose up -d ceph
```

* Display ceph container logs:
```
docker-compose logs -f ceph
```

* Access dashboard with credentials: admin / admin

https://127.0.0.1:$CEPH_HOST_PORT

Access dev. server dashboard when you see in container logs something like this:
```
ceph                 | *********
ceph                 | All done.
ceph                 | *********
```

http://127.0.0.1:$CEPH_PROXY_HOST_PORT

* Restart dashboard module:
```
docker-compose exec ceph /docker/restart-dashboard.sh
```

* Add OSD in 2nd host (once ceph dashboard is accessible):
```
docker-compose up -d --scale ceph-host2=1
```

* Stop all:
```
docker-compose down
```

### Build Ceph:
```
# Set a build-ready image and your local ccache path in .env file:
CEPH_IMAGE=rhcsdashboard/ceph:main  # DO NOT use ceph-rpm:... image.
HOST_CCACHE_DIR=/path/to/your/local/.ccache

docker-compose run --rm ceph /docker/build-ceph.sh
```

* Rebuild not proxied dashboard frontend:
```
docker-compose run --rm ceph /docker/build-dashboard-frontend.sh
```

### Backend unit tests and/or lint:
```
# All tests + lint:
docker-compose run --rm ceph /docker/ci/sanity-checks.sh run_tox

# Tests

# All tests:
docker-compose run --rm ceph /docker/ci/sanity-checks.sh run_tox py3
# All tests in nautilus branch:
docker-compose run --rm ceph /docker/ci/sanity-checks.sh run_tox py3-cov,py27-cov

# Only specific tests:
docker-compose run --rm ceph /docker/ci/sanity-checks.sh run_tox tests/test_rest_client.py tests/test_grafana.py

# Only 1 test:
docker-compose run --rm ceph /docker/ci/sanity-checks.sh run_tox tests/test_rgw_client.py::RgwClientTest::test_ssl_verify

# Run doctests in 1 file:
docker-compose run --rm ceph /docker/ci/sanity-checks.sh run_tox run -- pytest --doctest-modules tools.py

# Lint

# All files:
docker-compose run --rm ceph /docker/ci/sanity-checks.sh run_tox lint
# All files in nautilus branch:
docker-compose run --rm ceph /docker/ci/sanity-checks.sh run_tox py3-lint,py27-lint

# Only 1 file:
docker-compose run --rm ceph /docker/ci/sanity-checks.sh run_tox lint controllers/health.py
# Only 1 file in nautilus branch:
docker-compose run --rm ceph /docker/ci/sanity-checks.sh run_tox py3-run pylint controllers/health.py
docker-compose run --rm ceph /docker/ci/sanity-checks.sh run_tox py3-run pycodestyle controllers/health.py

# Other utilities

# Check OpenAPI Specification:
docker-compose run --rm ceph /docker/ci/sanity-checks.sh run_tox openapi-check

# List tox environmnets:
docker-compose run --rm ceph /docker/ci/sanity-checks.sh run_tox run tox -lv
```

* Check dashboard python code with **mypy**:
```
# Enable mypy check in .env file:
CHECK_MYPY=1

docker-compose run --rm ceph /docker/ci/sanity-checks.sh run_mypy

# Only 1 file:
docker-compose run --rm ceph /docker/ci/sanity-checks.sh run_mypy src/pybind/mgr/dashboard/controllers/rgw.py
```

* Run API tests (integration tests based on [Teuthology](https://github.com/ceph/teuthology)):
```
# Run tests interactively:
docker-compose run --rm -p 11000:11000 ceph bash
source /docker/ci/sanity-checks.sh && create_api_tests_cluster
run_teuthology_tests tasks.mgr.dashboard.test_health
run_teuthology_tests {moreTests}
cleanup_teuthology  # this also outputs coverage report.

# All tests:
docker-compose run --rm ceph /docker/ci/run-api-tests.sh

# Only specific tests:
docker-compose run --rm ceph /docker/ci/run-api-tests.sh tasks.mgr.dashboard.test_health tasks.mgr.dashboard.test_pool

# Only 1 test:
docker-compose run --rm ceph /docker/ci/run-api-tests.sh tasks.mgr.dashboard.test_rgw.RgwBucketTest.test_all
```

### Frontend unit tests or lint:
```
# Tests

# All tests:
docker-compose run --rm ceph /docker/ci/sanity-checks.sh run_jest

# Only specific tests:
docker-compose run --rm ceph /docker/ci/sanity-checks.sh run_jest health.component.spec.ts

# Only 1 test:
docker-compose run --rm ceph /docker/ci/sanity-checks.sh run_jest health.component.spec.ts -t "^HealthComponent should create$"

# Lint

# All files:
docker-compose run --rm ceph /docker/ci/sanity-checks.sh run_npm_lint
```

### Frontend E2E tests:
```
# If ceph is running:
docker-compose exec ceph /docker/ci/sanity-checks.sh run_frontend_e2e_tests
# Against a running nautilus cluster:
docker-compose run --rm -e DASHBOARD_URL=https://ceph:11000 ceph-e2e

# Only 1 specific test file:
docker-compose exec ceph /docker/ci/sanity-checks.sh run_frontend_e2e_tests --spec "cypress/integration/ui/dashboard.e2e-spec.ts"

# If ceph is not running:
docker-compose run --rm ceph /docker/ci/sanity-checks.sh run_frontend_e2e_tests
```

### Monitoring tests:
```
docker-compose run --rm ceph /docker/ci/sanity-checks.sh run_monitoring
```

### Sanity checks:
```
docker-compose run --rm ceph /docker/ci/run-sanity-checks.sh
```

### Build Ceph documentation:
```
docker-compose run --rm ceph /docker/ci/sanity-checks.sh run_build_doc
```

### Display Ceph documentation:
```
docker-compose run --rm -p 11001:8080 ceph /docker/ci/sanity-checks.sh run_serve_doc

# Access here: http://127.0.0.1:11001
```

## Grafana

If you have started grafana, you can access it at:

https://127.0.0.1:$GRAFANA_HOST_PORT/login

## Prometheus

If you have started prometheus, you can access it at:

http://127.0.0.1:$PROMETHEUS_HOST_PORT

## Single Sign-On (SSO)

Keycloak (open source Identity and Access Management solution)
will be used for authentication, so port 8080 must be available in your machine.

* Start Keycloak:
```
docker-compose up -d --scale keycloak=1 keycloak
```

You can access Keycloak administration console with credentials: admin / keycloak

http://127.0.0.1:8080 or https://127.0.0.1:8443

* Enable dashboard SSO in running ceph container:
```
docker-compose exec ceph /docker/sso/sso-enable.sh
```

* Access dashboard with SSO credentials: admin / ssoadmin

https://127.0.0.1:$CEPH_HOST_PORT

* Disable dashboard SSO:
```
docker-compose exec ceph /docker/sso/sso-disable.sh
```

## RGW Multi-Site

* Set appropriate values in *.env*:
```
RGW_MULTISITE=1
```

* Start ceph (cluster 1) + ceph2 (cluster 2):
```
docker-compose up -d --scale ceph2=1 --scale prometheus2=1
```

* Run 100s duration [benchmark](https://github.com/markhpc/hsbench#usage):
```
docker-compose exec ceph2 bash
hsbench -a <rgw-user-access-key> -s <rgw-user-secret-key> -u http://127.0.0.1:8000 -z 4K -d 100 -t 10 -b 10
```

## Access local dashboard connected to remote cluster

* Set appropriate values in *.env*:
```
DASHBOARD_URL=http://remote.ceph.cluster.com:8443
```

* Start only ceph:
```
docker-compose up -d ceph
```

## Build and push an image to docker registry:

* Build image:
```
docker build -t {imageName}:{imageTag} -f {/path/to/Dockerfile} ./docker/ceph

# Examples

# Build base image:
docker build -t rhcsdashboard/ceph-base:centos8 -f ./docker/ceph/centos/Dockerfile  ./docker/ceph

# Nightly ceph-rpm main:
docker build -t rhcsdashboard/ceph-rpm:main \
-f ./docker/ceph/rpm/Dockerfile ./docker/ceph \
--network=host

# Using custom repo URL (only for ceph-rpm images):
docker build -t rhcsdashboard/ceph-rpm:v16.2.0 \
-f ./docker/ceph/rpm/Dockerfile ./docker/ceph \
--build-arg REPO_URL=https://download.ceph.com/rpm-pacific/el8/x86_64/ \
--build-arg VCS_BRANCH=v16.2.0 \
--network=host

# Using custom repo files placed in './docker/ceph/rpm' (only for ceph-rpm images):
docker build -t rhcsdashboard/ceph-rpm:rhcs5.0 \
-f ./docker/ceph/rpm/Dockerfile ./docker/ceph \
--build-arg USE_REPO_FILES=1 \
--build-arg VCS_BRANCH=v16.2.0 \
--network=host

# Nautilus E2E image:
docker build -t rhcsdashboard/ceph-e2e:nautilus \
-f ./docker/ceph/e2e/Dockerfile ./docker/ceph \
--build-arg VCS_BRANCH=nautilus \
--network=host
```

* Optionally, create an additional tag:
```
docker tag {imageName}:{imageTag} {imageName}:{imageNewTag}

# Example:
docker tag rhcsdashboard/ceph:main rhcsdashboard/ceph:latest
```

* Log in to rhcs-dashboard docker registry:
```
docker login -u rhcsdashboard
```

* Push image:
```
docker push {imageName}:{imageTag}

# Example:
docker push rhcsdashboard/ceph:main
```

## Start Ceph 2 (useful for parallel development)

* Set your `CEPH2_` local values in *.env*.

* Start ceph2 + ceph + ...:
```
docker-compose up -d --scale ceph2=1 --scale prometheus2=1

# Start ceph2 but not ceph:
docker-compose up -d --scale ceph2=1 --scale ceph=0
```

## Start a downstream ceph product

* Set your `DOWNSTREAM_BUILD` to a product.

```
DOWNSTREAM_BUILD=redhat
```

and start the ceph normally.
```
docker-compose up -d ceph
```

## Kafka + Kafka UI deployment

To start a Kafka and Kafka UI for testing rgw notification specifically,
you can start the kafka and kafka-ui by

```
docker-compose up -d kafka
```
which will start both of them and kafka ui can be visible at http://localhost:8082
