# Deploy Ceph on Kubernetes with Rook

## Troubleshooting

Check [Rook Ceph Common Issues](https://rook.io/docs/rook/master/ceph-common-issues.html).

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

* Set virtualbox driver, start Minikube, add 3 additional Virtual Hard Disks (VHDs) to the VM manually:
```
minikube config set driver virtualbox
minikube start

# After adding the additional disks, check that they're available:
minikube ssh
lsblk
```

* Still inside minikube vm, create */var/lib/rook* folder, install *lvm2* package and exit vm:
```
sudo mkdir -p /var/lib/rook

# Enter minikube toolbox:
toolbox

# Install lvm2:
dnf install -y lvm2

# Exit toolbox:
exit

# Exit vm:
exit
```

* RECOMMENDED: create a VM snapshot in Virtualbox to restore the machine state when needed.

* Deploy Rook operator and Ceph cluster:
```
clone git@github.com:rook/rook.git
cd rook
git checkout v1.4.4
cd cluster/examples/kubernetes/ceph

kubectl create -f common.yaml
kubectl create -f operator.yaml
kubectl create -f cluster-test.yaml

kubectl config set-context minikube --namespace=rook-ceph
```

* Wait until all is up:
```
# Example:
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
rook-ceph-mgr-dashboard   ClusterIP   10.108.207.52    <none>        7000/TCP            92s
rook-ceph-mon-a           ClusterIP   10.105.226.195   <none>        6789/TCP,3300/TCP   2m10s
```

* Deploy Ceph Toolbox:
```
kubectl create -f toolbox.yaml

# Access toolbox CLI:
kubectl -n rook-ceph exec -it $(kubectl -n rook-ceph get pod -l "app=rook-ceph-tools" -o jsonpath='{.items[0].metadata.name}') -- bash

# Then you can run commands like: ceph -s
```

* Create an Object Store and wait until the service is up:
```
kubectl create -f object-test.yaml

# Example:
$ kubectl get pod | grep rgw
rook-ceph-rgw-my-store-a-764f68c645-fcjdn       1/1     Running     0          15s
```

* Create an Object Store user credentials to the dashboard:
```
kubectl create -f object-user.yaml

# Access key:
echo $(kubectl -n rook-ceph get secret rook-ceph-object-user-my-store-my-user -o yaml | grep AccessKey | awk '{print $2}' | base64 --decode)

# Secret key:
echo $(kubectl -n rook-ceph get secret rook-ceph-object-user-my-store-my-user -o yaml | grep SecretKey | awk '{print $2}' | base64 --decode)

# Access toolbox CLI:
kubectl -n rook-ceph exec -it $(kubectl -n rook-ceph get pod -l "app=rook-ceph-tools" -o jsonpath='{.items[0].metadata.name}') -- bash

# Enable system flag on the user (required for dashboard Object Gateway management):
radosgw-admin user modify --uid=my-user --system

# Provide the user credentials to the dashboard:
ceph dashboard set-rgw-api-user-id my-user
ceph dashboard set-rgw-api-access-key <access-key>
ceph dashboard set-rgw-api-secret-key <secret-key>
```

* Make dashboard accessible from outside:
```
kubectl create -f dashboard-external-http.yaml

# Example:
$ kubectl get svc| grep dashboard-external-http
rook-ceph-mgr-dashboard-external-http   NodePort    10.96.116.254    <none>        7000:32341/TCP      2d
```

* Obtain Minikube IP and access the dashboard using the **rook-ceph-mgr-dashboard-external-http** service opened port:
```
# IP:
minikube ip

# Example: dashboard URL
https://192.168.99.101:32341
```

* Get dashboard **admin** user password:
```
echo $(kubectl get secret rook-ceph-dashboard-password -o yaml | grep "password:" | awk '{print $2}' | base64 --decode)
```

## Remote OpenShift 4 cluster

* Download OpenShift Client:
```
sudo mkdir -p /opt/openshift-client
sudo curl -LsS -o /opt/openshift-client/openshift-client.tar.gz https://mirror.openshift.com/pub/openshift-v4/clients/ocp/latest/openshift-client-linux-4.5.11.tar.gz
sudo tar -xzvf /opt/openshift-client/openshift-client.tar.gz -C /opt/openshift-client
sudo ln -sf /opt/openshift-client/oc /usr/local/bin/oc
sudo ln -sf /opt/openshift-client/kubectl /usr/local/bin/kubectl
```

* Log in with admin user:
```
# Example: after 'cluster-bot' cluster is ready
oc login -u kubeadmin https://api.ci-ln-67pkfcb-d5d6b.origin-ci-int-aws.dev.rhcloud.com:6443
```

* Deploy Rook operator and Ceph cluster:
```
clone git@github.com:rook/rook.git
cd rook
git checkout v1.4.4
cd cluster/examples/kubernetes/ceph

oc create -f common.yaml
oc create -f operator-openshift.yaml
oc create -f cluster-on-pvc.yaml

oc project rook-ceph
```

* Wait until all is up:
```
# Example:
$ oc get pod
NAME                                          READY   STATUS      RESTARTS   AGE
rook-ceph-agent-r67zt                         1/1     Running     0          3m1s
rook-ceph-agent-vkqs8                         1/1     Running     0          3m1s
rook-ceph-agent-z8lkm                         1/1     Running     0          3m1s
rook-ceph-mgr-a-6f89574945-h7z78              1/1     Running     0          68s
rook-ceph-mon-a-5b7f8c74b8-r2tsn              1/1     Running     0          87s
rook-ceph-operator-86554dcbfc-mcbdm           1/1     Running     0          3m46s
rook-ceph-osd-0-7f6db68447-hxfp5              1/1     Running     0          28s
rook-ceph-osd-1-67864f4cc7-dfv58              1/1     Running     0          25s
rook-ceph-osd-2-6774cdc8ff-xxfxn              1/1     Running     0          25s
rook-ceph-osd-prepare-ip-10-0-129-139-xccn4   0/2     Completed   0          39s
rook-ceph-osd-prepare-ip-10-0-132-164-wmmts   0/2     Completed   0          39s
rook-ceph-osd-prepare-ip-10-0-148-37-hvhnh    0/2     Completed   0          39s
rook-discover-j8nzq                           1/1     Running     0          3m1s
rook-discover-t2lt4                           1/1     Running     0          3m1s
rook-discover-t5qgb                           1/1     Running     0          3m1s

$ oc get svc
NAME                      TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)             AGE
rook-ceph-mgr             ClusterIP   172.30.11.40     <none>        9283/TCP            79s
rook-ceph-mgr-dashboard   ClusterIP   172.30.203.185   <none>        8443/TCP            80s
rook-ceph-mon-a           ClusterIP   172.30.45.236    <none>        6789/TCP,3300/TCP   2m9s
```

* Deploy Ceph Toolbox.
```
oc create -f toolbox.yaml
oc -n rook-ceph exec -it $(oc -n rook-ceph get pod -l "app=rook-ceph-tools" -o jsonpath='{.items[0].metadata.name}') -- bash
```

* Create an Object Store and wait until the service is up:
```
oc create -f object-openshift.yaml

# Example:
$ oc get pod | grep rgw
rook-ceph-rgw-my-store-a-764f68c645-fcjdn       1/1     Running     0          15s
```

* Create an Object Store user credentials to the dashboard:
```
oc create -f object-user.yaml

# Access key:
echo $(oc -n rook-ceph get secret rook-ceph-object-user-my-store-my-user -o yaml | grep AccessKey | awk '{print $2}' | base64 --decode)

# Secret key:
echo $(oc -n rook-ceph get secret rook-ceph-object-user-my-store-my-user -o yaml | grep SecretKey | awk '{print $2}' | base64 --decode)

# Access toolbox CLI:
oc -n rook-ceph exec -it $(oc -n rook-ceph get pod -l "app=rook-ceph-tools" -o jsonpath='{.items[0].metadata.name}') -- bash

# Enable system flag on the user (required for dashboard Object Gateway management):
radosgw-admin user modify --uid=my-user --system

# Provide the user credentials to the dashboard:
ceph dashboard set-rgw-api-user-id my-user
ceph dashboard set-rgw-api-access-key <access-key>
ceph dashboard set-rgw-api-secret-key <secret-key>
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
oc create -f dashboard-loadbalancer.yaml

# Example:
$ oc get svc
NAME                                     TYPE           CLUSTER-IP       EXTERNAL-IP                                                               PORT(S)             AGE
rook-ceph-mgr                            ClusterIP      172.30.11.40     <none>                                                                    9283/TCP            4m37s
rook-ceph-mgr-dashboard                  ClusterIP      172.30.203.185   <none>                                                                    8443/TCP            4m38s
rook-ceph-mgr-dashboard-loadbalancer     LoadBalancer   172.30.27.242    a7f23e8e2839511e9b7a5122b08f2038-1251669398.us-east-1.elb.amazonaws.com   8443:32747/TCP      4s
rook-ceph-mon-a                          ClusterIP      172.30.45.236    <none>                                                                    6789/TCP,3300/TCP   5m27s
rook-ceph-rgw-my-store                   ClusterIP      172.30.18.97     <none>                                                                    8080/TCP            2m16s                                                                   6789/TCP,3300/TCP   65m
```

* Access dashboard:
```
# HTTP example:
http://rook-ceph-mgr-dashboard-rook-ceph.apps.ci-ln-kj3t5ck-d5d6b.origin-ci-int-aws.dev.rhcloud.com

# HTTPS example:
https://a7f23e8e2839511e9b7a5122b08f2038-1251669398.us-east-1.elb.amazonaws.com:8443
```

* Get dashboard **admin** user password following the Minikube cluster step.
