ARG CENTOS_VERSION=8
FROM rhcsdashboard/ceph-base:centos_stream${CENTOS_VERSION}
ARG CENTOS_VERSION

# Required in order for build-doc to run successfully:
RUN pip3 install -U Cython==0.29.3

RUN dnf install -y bc ccache systemd-udev \
    && dnf clean packages

ARG VCS_BRANCH=main
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

RUN dnf clean all && rm -rf /var/cache/dnf/*

COPY install-node.sh /root
RUN /root/install-node.sh
