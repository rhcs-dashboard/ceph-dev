# Deploy Ceph on OpenShift with Rook

## Fedora

* Install [OpenShift](https://developer.fedoraproject.org/deployment/openshift/about.html):
```
sudo dnf install origin-clients docker
```

* Update docker configuration:
```
echo "[registries.insecure]
registries = ['172.30.0.0/16']" | sudo tee /etc/containers/registries.conf

sudo sed -i -e "s/dockerd -H/dockerd --insecure-registry 172.30.0.0\/16 -H/" /usr/lib/systemd/system/docker.service

sudo systemctl daemon-reload
sudo systemctl restart docker
```

* If they not already exist, create necessary directories:
```
sudo mkdir -p /usr/libexec/kubernetes/kubelet-plugins/volume/exec
sudo mkdir -p /var/lib/rook
```

* Start cluster:
```
git clone git@github.com:rhcs-dashboard/ceph-dev.git
cd ceph-dev
oc cluster up
```

* Add role *cluster-admin* to default user *developer* and log in as *developer*:
```
oc login -u system:admin
oc adm policy add-cluster-role-to-user cluster-admin developer
oc login -u developer -p 1
```

* Create Security Context Constraints:
```
oc create -f deployment/rook/scc.yaml
```

* Create project *rook-ceph-system*:
```
oc create -f deployment/rook/operator.yaml
```

* Check that pods are running:
```
oc project rook-ceph-system
oc get pods

# Example:
NAME                                 READY     STATUS    RESTARTS   AGE
rook-ceph-agent-b6kq6                1/1       Running   0          40s
rook-ceph-operator-b76466dcd-544b7   1/1       Running   0          1m
rook-discover-9wpdx                  1/1       Running   0          40s
```

* Create project *rook-ceph*:
```
oc create -f deployment/rook/cluster.yaml
```

* Check that pods are running:
```
oc project rook-ceph
oc get pods

# Example:
NAME                                    READY     STATUS      RESTARTS   AGE
rook-ceph-mgr-a-65445fd5f9-hvm6d        1/1       Running     0          42s
rook-ceph-mon-a-78bd888d8c-gwt5p        1/1       Running     0          1m
rook-ceph-mon-b-65475f8fff-dv6kl        1/1       Running     0          1m
rook-ceph-mon-c-7bc47c9d8b-gxtzd        1/1       Running     0          1m
rook-ceph-osd-0-684785fb6f-qqjwp        1/1       Running     0          19s
rook-ceph-osd-prepare-localhost-stlz2   0/2       Completed   0          26s
```

* Check that service *rook-ceph-mgr-dashboard* is running:
```
oc get services

# Example:
NAME                      TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)    AGE
rook-ceph-mgr             ClusterIP   172.30.129.40    <none>        9283/TCP   2m
rook-ceph-mgr-dashboard   ClusterIP   172.30.18.215    <none>        8443/TCP   2m
rook-ceph-mon-a           ClusterIP   172.30.193.215   <none>        6790/TCP   3m
rook-ceph-mon-b           ClusterIP   172.30.244.112   <none>        6790/TCP   3m
rook-ceph-mon-c           ClusterIP   172.30.45.124    <none>        6790/TCP   3m
```

* Get password for dashboard user *admin* and use *rook-ceph-mgr-dashboard* service IP:PORT to access dashboard:
```
# Password:
echo $(oc get secret rook-ceph-dashboard-password -o yaml | grep "password:" | awk '{print $2}' | base64 --decode)

# Example:
https://172.30.18.215:8443/#/login
```

## Troubleshooting

Check Rook [Common Issues](https://rook.io/docs/rook/v0.9/common-issues.html).