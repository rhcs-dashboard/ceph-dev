ARG CENTOS_VERSION=8
FROM rhcsdashboard/ceph-base:centos${CENTOS_VERSION}
ARG CENTOS_VERSION

# Sepia provide missing dependencies until epel provide all dependencies.
RUN dnf config-manager --add-repo http://apt-mirror.front.sepia.ceph.com/lab-extras/${CENTOS_VERSION}/
RUN dnf config-manager --setopt gpgcheck=0 apt-mirror.front.sepia.ceph.com_lab-extras_${CENTOS_VERSION}_ --save
RUN dnf copr enable -y ktdreyer/ceph-el${CENTOS_VERSION}

ARG REPO_URL
ARG CEPH_RELEASE=master
COPY rpm/set-ceph-repo.sh /root
RUN /root/set-ceph-repo.sh
RUN dnf install -y --nogpgcheck ceph ceph-mgr-dashboard ceph-mgr-diskprediction-local \
    ceph-radosgw rbd-mirror \
    && dnf clean packages

# Install doc-build deps.
# Fedora provide missing dependencies until epel provide all dependencies.
COPY fedora/fedora.repo /etc/yum.repos.d
RUN dnf install -y ditaa \
    && dnf clean packages
RUN dnf config-manager --set-disabled fedora
RUN dnf install -y ant doxygen libxslt-devel libxml2-devel graphviz python3-devel python3-pip python3-virtualenv \
    python3-Cython \
    && dnf clean all

RUN rm -rf /var/cache/dnf/*

ARG VCS_BRANCH=master
COPY install-node.sh /root
RUN /root/install-node.sh