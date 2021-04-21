ARG CENTOS_VERSION=8
FROM rhcsdashboard/ceph-base:centos${CENTOS_VERSION}
ARG CENTOS_VERSION

# Required in order for build-doc to run successfully:
RUN pip3 install -U Cython==0.29.3

RUN dnf install -y ccache \
    && dnf clean packages

ARG VCS_BRANCH=master
RUN curl -LsS https://raw.githubusercontent.com/ceph/ceph/"$VCS_BRANCH"/install-deps.sh \
    -o /ceph/install-deps.sh \
    && chmod +x /ceph/install-deps.sh
RUN curl -LsS https://raw.githubusercontent.com/ceph/ceph/"$VCS_BRANCH"/ceph.spec.in \
    -o /ceph/ceph.spec.in

ARG FOR_MAKE_CHECK=1
RUN bash -x /ceph/install-deps.sh \
    && dnf clean packages

RUN dnf install -y ninja-build \
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

COPY install-node.sh /root
RUN /root/install-node.sh
