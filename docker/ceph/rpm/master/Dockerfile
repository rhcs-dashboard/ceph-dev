ARG CENTOS_VERSION=8
FROM rhcsdashboard/ceph-base:centos${CENTOS_VERSION}
ARG CENTOS_VERSION

# Sepia provide missing dependencies until epel provide all dependencies.
RUN dnf config-manager --add-repo http://apt-mirror.front.sepia.ceph.com/lab-extras/${CENTOS_VERSION}/
RUN dnf config-manager --setopt gpgcheck=0 apt-mirror.front.sepia.ceph.com_lab-extras_${CENTOS_VERSION}_ --save
RUN dnf copr enable -y ktdreyer/ceph-el${CENTOS_VERSION}

RUN sed -i 's/gpgcheck=1/gpgcheck=0/' /etc/dnf/dnf.conf

ARG REPO_URL
COPY rpm/set-ceph-repo.sh /root
RUN /root/set-ceph-repo.sh
RUN dnf install -y ceph ceph-mgr-dashboard ceph-mgr-diskprediction-local ceph-radosgw rbd-mirror \
    && dnf clean all

RUN rm -rf /var/cache/dnf/*

ARG VCS_BRANCH=master
COPY install-node.sh /root
RUN /root/install-node.sh