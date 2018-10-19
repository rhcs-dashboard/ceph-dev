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

CEPH_REPO_DIR=/path/to/your/local/ceph/repo
HOST_CCACHE_DIR=/path/to/your/local/.ccache/dir

DASHBOARD_HOST_PORT=4200    (example: set 5200 if you want to access the dashboard at http://localhost:5200)
GRAFANA_HOST_PORT=3000    (default: 3000)
PROMETHEUS_HOST_PORT=9090    (default: 9090)
```

* Log in to rhcs-dashboard docker registry and download images:
```
docker login -u rhcsdashboard
docker-compose pull
```

* Optionally, set up git pre-commit hook:
```
cp scripts/git/pre-commit.sh /path/to/your/local/ceph/repo/.git/hooks/pre-commit
```

## Usage

* Build Ceph:
```
docker-compose run --rm ceph /docker/build-ceph.sh
```

* Start only ceph:
```
docker-compose up -d ceph
```

* Start ceph + grafana + prometheus:
```
docker-compose up -d
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

http://localhost:$DASHBOARD_HOST_PORT

* Access dashboard:

https://localhost:11000

* Rebuild not proxied dashboard frontend:
```
docker-compose exec ceph /docker/build-dashboard-frontend.sh
```

* Restart dashboard:
```
docker-compose exec ceph /docker/restart-dashboard.sh
```

* Stop all:
```
docker-compose down
```

* Run pre-commit hook:
```
# If hook has been set up:
docker-compose run --rm ceph /ceph/.git/hooks/pre-commit

# If hook hasn't been set up:
docker-compose run --rm -v $(pwd)/scripts:/scripts ceph /scripts/git/pre-commit.sh
```

## Grafana

If you have started grafana, you can access it at:
http://localhost:$GRAFANA_HOST_PORT/login

## Prometheus

If you have started prometheus, you can access it at:
http://localhost:$PROMETHEUS_HOST_PORT

## Teuthology (Ceph integration test framework)

* Install Teuthology in a temporary folder and start a cluster:
```
docker-compose run --rm ceph bash
cd src/pybind/mgr/dashboard
source ./run-backend-api-tests.sh
```

* Run tests (example: only dashboard tests):
```
run_teuthology_tests tasks.mgr.dashboard.test_dashboard.DashboardTest
```

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

## Start Luminous using installed RPM version

* Clone Ceph repo in directory called **luminous** and switch to branch v12.2.7:
```
git clone git@github.com:rhcs-dashboard/ceph-dev.git luminous
git checkout v12.2.7
```

* In *.env* file (ceph-dev repo), set the following values:
```
LUMINOUS_REPO_DIR=/path/to/your/local/luminous
LUMINOUS_START_FROM_RPM=1
```

* In *docker-compose.yml*, uncomment the **luminous** service.

* Download luminous docker image:
```
docker-compose pull
```

* Start luminous:
```
docker-compose up -d luminous
```
