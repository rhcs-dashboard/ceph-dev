ARG CENTOS_VERSION=9
FROM rhcsdashboard/ceph-base:centos_stream${CENTOS_VERSION}
ARG CENTOS_VERSION

# Sepia provide missing dependencies until epel provide all dependencies.
RUN dnf config-manager --add-repo http://apt-mirror.front.sepia.ceph.com/lab-extras/${CENTOS_VERSION}/
RUN dnf config-manager --setopt gpgcheck=0 apt-mirror.front.sepia.ceph.com_lab-extras_${CENTOS_VERSION}_ --save
RUN dnf copr enable -y ceph/el${CENTOS_VERSION}

ARG VCS_BRANCH=main
RUN curl -LsS https://raw.githubusercontent.com/ceph/ceph/"$VCS_BRANCH"/install-deps.sh \
    -o /ceph/install-deps.sh \
    && chmod +x /ceph/install-deps.sh
RUN (curl -LsS https://raw.githubusercontent.com/ceph/ceph/"$VCS_BRANCH"/src/script/lib-build.sh \
    -o /ceph/src/script/lib-build.sh --create-dirs \
    && chmod +x /ceph/src/script/lib-build.sh ) || true
RUN curl -LsS https://raw.githubusercontent.com/ceph/ceph/"$VCS_BRANCH"/ceph.spec.in \
    -o /ceph/ceph.spec.in

RUN bash -x /ceph/install-deps.sh \
    && dnf clean packages

ARG USE_REPO_FILES=0
ARG REPO_URL
ARG CEPH_RELEASE=main
COPY rpm/*.* /root/
RUN /root/set-ceph-repo.sh
RUN dnf install -y --nogpgcheck ceph-mds ceph-mgr-cephadm ceph-mgr-dashboard \
    ceph-exporter \
    ceph-mgr-diskprediction-local \
    ceph-mon ceph-osd ceph-radosgw rbd-mirror \
    && dnf clean packages

RUN dnf clean all && rm -rf /var/cache/dnf/*

ARG VCS_BRANCH=main
COPY install-node.sh /root
RUN /root/install-node.sh
