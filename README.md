![Publish ceph images](https://github.com/rhcs-dashboard/ceph-dev/workflows/Publish%20ceph%20images/badge.svg?branch=master)

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
1. The dashboard will be available at: `https://localhost:11000` with credentials: `admin / admin`.

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

* Start ceph + dashboard feature services:
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

https://localhost:$CEPH_HOST_PORT

Access dev. server dashboard when you see in container logs something like this:
```
ceph                 | *********
ceph                 | All done.
ceph                 | *********
```

http://localhost:$CEPH_PROXY_HOST_PORT

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

* Build Ceph:
```
# Set a build-ready image and your local ccache path in .env file:
CEPH_IMAGE=rhcsdashboard/ceph:master  # DO NOT use ceph-rpm:... image.
HOST_CCACHE_DIR=/path/to/your/local/.ccache

docker-compose run --rm ceph /docker/build-ceph.sh
```

* Rebuild not proxied dashboard frontend:
```
docker-compose run --rm ceph /docker/build-dashboard-frontend.sh
```

* Run backend unit tests and/or lint:
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

* Run frontend unit tests or lint:
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

* Run frontend E2E tests:
```
# If ceph is running:
docker-compose exec ceph /docker/ci/sanity-checks.sh run_frontend_e2e_tests

# Only 1 specific test file:
docker-compose exec ceph /docker/ci/sanity-checks.sh run_frontend_e2e_tests --spec "cypress/integration/ui/dashboard.e2e-spec.ts"

# If ceph is not running:
docker-compose run --rm ceph /docker/ci/sanity-checks.sh run_frontend_e2e_tests
```

* Run sanity checks:
```
docker-compose run --rm ceph /docker/ci/run-sanity-checks.sh
```

* Build Ceph documentation:
```
docker-compose run --rm ceph /docker/ci/sanity-checks.sh run_build_doc
```

* Display Ceph documentation:
```
docker-compose run --rm -p 11001:8080 ceph /docker/ci/sanity-checks.sh run_serve_doc

# Access here: http://localhost:11001
```

## Grafana

If you have started grafana, you can access it at:

http://localhost:$GRAFANA_HOST_PORT/login

## Prometheus

If you have started prometheus, you can access it at:

http://localhost:$PROMETHEUS_HOST_PORT

## Single Sign-On (SSO)

Keycloak (open source Identity and Access Management solution)
will be used for authentication, so localhost port 8080 must be available.

* Start Keycloak:
```
docker-compose up -d --scale keycloak=1 keycloak
```

You can access Keycloak administration console with credentials: admin / keycloak

http://localhost:8080 or https://localhost:8443

* Enable dashboard SSO in running ceph container:
```
docker-compose exec ceph /docker/sso/sso-enable.sh
```

* Access dashboard with SSO credentials: admin / ssoadmin

https://localhost:$CEPH_HOST_PORT

* Disable dashboard SSO:
```
docker-compose exec ceph /docker/sso/sso-disable.sh
```

## RGW Multi-Site

* Set appropriate values in *.env*:
```
RGW_MULTISITE=1
```

* Start ceph (cluster 1) + ceph cluster 2:
```
docker-compose up -d --scale ceph-cluster2=1
```

* Run 100s duration [benchmark](https://github.com/markhpc/hsbench#usage):
```
docker-compose exec ceph-cluster2 bash
hsbench -a <rgw-user-access-key> -s <rgw-user-secret-key> -u http://127.0.0.1:8000 -z 4K -d 100 -t 10 -b 10
```

## Access local dashboard connected to remote cluster

* Set appropriate values in *.env*:
```
REMOTE_DASHBOARD_URL=http://remote.ceph.cluster.com:8443
```

* Start only ceph:
```
docker-compose up -d ceph
```

## Build and push an image to docker registry:

If you want to update an image, you'll have to edit image's Dockerfile and then:

* Build image:
```
docker build -t {imageName}:{imageTag} -f {/path/to/Dockerfile} ./docker/ceph

# Example:
docker build -t rhcsdashboard/ceph:master -f ./docker/ceph/master/Dockerfile  ./docker/ceph
```

* Optionally, create an additional tag:
```
docker tag {imageName}:{imageTag} {imageName}:{imageNewTag}

# Example:
docker tag rhcsdashboard/ceph:master rhcsdashboard/ceph:latest
```

* Log in to rhcs-dashboard docker registry:
```
docker login -u rhcsdashboard
```

* Push image:
```
docker push {imageName}:{imageTag}

# Example:
docker push rhcsdashboard/ceph:master
```

## Start Ceph 2 (useful for parallel development)

* Set your `CEPH2_` local values in *.env*.

* Start ceph2 + ceph + ...:
```
docker-compose up -d --scale ceph2=1

# Start ceph2 but not ceph:
docker-compose up -d --scale ceph2=1 --scale ceph=0
```
