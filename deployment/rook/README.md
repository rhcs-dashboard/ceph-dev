# Deploy Ceph on Kubernetes with Rook

## Minikube cluster

* Install Minikube:
```
sudo curl -o /usr/local/bin/minikube \
-LsS https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64 \
&& sudo chmod +x /usr/local/bin/minikube
```

* Install kubectl:
```
sudo curl -o /usr/local/bin/kubectl \
-LsS https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl \
&& sudo chmod +x /usr/local/bin/kubectl
```

* Optionally, clean old Minikube setup:
```
rm -rf ~/.minikube
```

* Start Minikube and switch to its cluster:
```
minikube start
kubectl config use-context minikube
```

* Create rook-ceph project and deploy it:
```
git clone git@github.com:rhcs-dashboard/ceph-dev.git
cd ceph-dev
kubectl create -f deployment/rook/common.yaml -f deployment/rook/operator.yaml
kubectl create -f deployment/rook/cluster-test-minikube.yaml
```

* Wait until all is up:
```
# Example:
$ kubectl config set-context $(kubectl config current-context) --namespace=rook-ceph

$ kubectl get pod
NAME                                   READY   STATUS      RESTARTS   AGE
rook-ceph-agent-qrxt6                  1/1     Running     0          3m6s
rook-ceph-mgr-a-9cd77c86d-l44rq        1/1     Running     0          85s
rook-ceph-mon-a-9bb9c767f-g8b6h        1/1     Running     0          97s
rook-ceph-operator-5d4dff848d-4fvcc    1/1     Running     0          3m7s
rook-ceph-osd-0-5776f54578-2rkgh       1/1     Running     0          53s
rook-ceph-osd-prepare-minikube-lvj4b   0/2     Completed   1          61s
rook-discover-t2thc                    1/1     Running     0          3m6s

$ kubectl get svc
NAME                      TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)             AGE
rook-ceph-mgr             ClusterIP   10.108.255.209   <none>        9283/TCP            92s
rook-ceph-mgr-dashboard   ClusterIP   10.108.207.52    <none>        8443/TCP            92s
rook-ceph-mon-a           ClusterIP   10.105.226.195   <none>        6789/TCP,3300/TCP   2m10s
```

* Optionally, deploy Rook Ceph Toolbox:
```
kubectl create -f deployment/rook/toolbox.yaml

# Access toolbox CLI:
kubectl -n rook-ceph exec -it $(kubectl -n rook-ceph get pod -l "app=rook-ceph-tools" -o jsonpath='{.items[0].metadata.name}') bash

# Then you can run commands like: ceph -s
```

* Optionally, create an Object Store and a user:
```
kubectl create -f deployment/rook/object-test.yaml
kubectl create -f deployment/rook/object-user.yaml

# Example:
$ kc get pod
NAME                                      READY   STATUS      RESTARTS   AGE
rook-ceph-agent-qrxt6                     1/1     Running     0          5m39s
rook-ceph-mgr-a-9cd77c86d-l44rq           1/1     Running     0          3m58s
rook-ceph-mon-a-9bb9c767f-g8b6h           1/1     Running     0          4m10s
rook-ceph-operator-5d4dff848d-4fvcc       1/1     Running     0          5m40s
rook-ceph-osd-0-5776f54578-2rkgh          1/1     Running     0          3m26s
rook-ceph-osd-prepare-minikube-lvj4b      0/2     Completed   1          3m34s
rook-ceph-rgw-my-store-75b476866d-9s2xg   1/1     Running     0          18s
rook-ceph-tools-b8c679f95-rhkjs           1/1     Running     0          94s
rook-discover-t2thc                       1/1     Running     0          5m39s
```

* Make dashboard accessible from outside:
```
kubectl create -f deployment/rook/dashboard-external-https.yaml

# Example:
$ kubectl get svc
NAME                                     TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)             AGE
rook-ceph-mgr                            ClusterIP   10.108.255.209   <none>        9283/TCP            4m42s
rook-ceph-mgr-dashboard                  ClusterIP   10.108.207.52    <none>        8443/TCP            4m42s
rook-ceph-mgr-dashboard-external-https   NodePort    10.106.127.150   <none>        8443:32361/TCP      7s
rook-ceph-mon-a                          ClusterIP   10.105.226.195   <none>        6789/TCP,3300/TCP   5m20s
rook-ceph-rgw-my-store                   ClusterIP   10.104.24.38     <none>        80/TCP              110s
```

* Obtain Minikube IP and access the dashboard using the **rook-ceph-mgr-dashboard-external-https** service opened port:
```
# IP:
minikube ip

# Example: dashboard URL
https://192.168.99.101:32361
```

* Get dashboard **admin** user password:
```
echo $(kubectl get secret rook-ceph-dashboard-password -o yaml | grep "password:" | awk '{print $2}' | base64 --decode)
```

## Remote OpenShift 4.1 cluster

* Download OpenShift Client:
```
sudo mkdir -p /opt/openshift-client
sudo curl -LsS -o /opt/openshift-client/openshift-client.tar.gz https://mirror.openshift.com/pub/openshift-v4/clients/ocp/latest/openshift-client-linux-4.1.0-rc.3.tar.gz
sudo tar -xzvf /opt/openshift-client/openshift-client.tar.gz -C /opt/openshift-client
sudo ln -sf /opt/openshift-client/oc /usr/local/bin/oc
sudo ln -sf /opt/openshift-client/kubectl /usr/local/bin/kubectl
```

* Log in with admin user:
```
# Example: after 'cluster-bot' cluster is ready
oc login -u kubeadmin https://api.ci-ln-67pkfcb-d5d6b.origin-ci-int-aws.dev.rhcloud.com:6443
```

* Create rook-ceph project and deploy it:
```
git clone git@github.com:rhcs-dashboard/ceph-dev.git
cd ceph-dev
oc create -f deployment/rook/common.yaml -f deployment/rook/operator-openshift.yaml

# Choose HTTP or HTTPS:
# HTTP:
oc create -f deployment/rook/cluster-openshift-http.yaml

# HTTPS:
oc create -f deployment/rook/cluster-openshift-https.yaml
```

* Wait until all is up:
```
# Example:
$ oc project rook-ceph

$ oc get pod
NAME                                          READY   STATUS      RESTARTS   AGE
rook-ceph-agent-5qw8x                         1/1     Running     0          54m
rook-ceph-agent-fjztt                         1/1     Running     0          54m
rook-ceph-agent-j9d46                         1/1     Running     0          54m
rook-ceph-mgr-a-574ff86dc6-hc44w              1/1     Running     0          53m
rook-ceph-mon-a-7bb7d9d79d-bm2qs              1/1     Running     0          54m
rook-ceph-mon-b-7dd7548f7b-fzg75              1/1     Running     0          53m
rook-ceph-mon-c-66897b47ff-258cx              1/1     Running     0          53m
rook-ceph-operator-699f75f566-kvgr4           1/1     Running     0          55m
rook-ceph-osd-prepare-ip-10-0-134-158-cpq6v   0/2     Completed   0          52m
rook-ceph-osd-prepare-ip-10-0-138-176-nbqvq   0/2     Completed   0          52m
rook-ceph-osd-prepare-ip-10-0-146-129-l2fsm   0/2     Completed   0          52m
rook-discover-mww52                           1/1     Running     0          54m
rook-discover-qxj4x                           1/1     Running     0          54m
rook-discover-tp7jl                           1/1     Running     0          54m

$ oc get svc
NAME                      TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)             AGE
rook-ceph-mgr             ClusterIP   172.30.35.196    <none>        9283/TCP            52m
rook-ceph-mgr-dashboard   ClusterIP   172.30.205.217   <none>        8443/TCP            52m
rook-ceph-mon-a           ClusterIP   172.30.193.208   <none>        6789/TCP,3300/TCP   54m
rook-ceph-mon-b           ClusterIP   172.30.50.1      <none>        6789/TCP,3300/TCP   53m
rook-ceph-mon-c           ClusterIP   172.30.83.146    <none>        6789/TCP,3300/TCP   53m
```

* Optionally, deploy Rook Ceph Toolbox:
```
oc create -f deployment/rook/toolbox.yaml

# Access toolbox CLI:
oc exec -it $(oc get pod -l "app=rook-ceph-tools" -o jsonpath='{.items[0].metadata.name}') bash

# Then you can run commands like: ceph -s
```

* Optionally, create an Object Store and a user:
```
oc create -f deployment/rook/object-openshift.yaml
oc create -f deployment/rook/object-user.yaml
```

* Make dashboard accessible from outside:
```
# HTTP:
oc expose service rook-ceph-mgr-dashboard

# Example:
$ oc get route
NAME                      HOST/PORT                                                                                      PATH   SERVICES                  PORT              TERMINATION   WILDCARD
rook-ceph-mgr-dashboard   rook-ceph-mgr-dashboard-rook-ceph.apps.ci-ln-kj3t5ck-d5d6b.origin-ci-int-aws.dev.rhcloud.com          rook-ceph-mgr-dashboard   https-dashboard                 None


# HTTPS:
oc create -f deployment/rook/dashboard-external-https-openshift.yaml

# Example:
$ oc get svc
NAME                                     TYPE           CLUSTER-IP       EXTERNAL-IP                                                               PORT(S)             AGE
rook-ceph-mgr                            ClusterIP      172.30.187.212   <none>                                                                    9283/TCP            64m
rook-ceph-mgr-dashboard                  ClusterIP      172.30.107.238   <none>                                                                    8443/TCP            64m
rook-ceph-mgr-dashboard-external-https   LoadBalancer   172.30.214.229   af1f7d97b82d811e9acb0129043356ed-1688131122.us-east-1.elb.amazonaws.com   8443:32265/TCP      5s
rook-ceph-mon-a                          ClusterIP      172.30.113.207   <none>                                                                    6789/TCP,3300/TCP   66m
rook-ceph-mon-b                          ClusterIP      172.30.213.172   <none>                                                                    6789/TCP,3300/TCP   66m
rook-ceph-mon-c                          ClusterIP      172.30.167.71    <none>                                                                    6789/TCP,3300/TCP   65m
```

* Access dashboard:
```
# HTTP example:
http://rook-ceph-mgr-dashboard-rook-ceph.apps.ci-ln-kj3t5ck-d5d6b.origin-ci-int-aws.dev.rhcloud.com

# HTTPS example:
https://af1f7d97b82d811e9acb0129043356ed-1688131122.us-east-1.elb.amazonaws.com:8443
```

* Get dashboard **admin** user password:
```
echo $(kubectl get secret rook-ceph-dashboard-password -o yaml | grep "password:" | awk '{print $2}' | base64 --decode)
```

## Local OpenShift 3.11 cluster on Fedora

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

Check [Rook Ceph Common Issues](https://rook.io/docs/rook/master/ceph-common-issues.html).
