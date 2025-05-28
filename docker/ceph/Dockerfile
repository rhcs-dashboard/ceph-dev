ARG CENTOS_VERSION=9
FROM rhcsdashboard/ceph-base:centos_stream${CENTOS_VERSION}
ARG CENTOS_VERSION

# Required in order for build-doc to run successfully:
RUN pip3 install -U Cython

RUN dnf install -y bc ccache systemd-udev \
    && dnf clean packages

ARG VCS_BRANCH=main
RUN curl -LsS https://raw.githubusercontent.com/ceph/ceph/"$VCS_BRANCH"/install-deps.sh \
    -o /ceph/install-deps.sh \
    && chmod +x /ceph/install-deps.sh
RUN (curl -LsS https://raw.githubusercontent.com/ceph/ceph/"$VCS_BRANCH"/src/script/lib-build.sh \
    -o /ceph/src/script/lib-build.sh --create-dirs \
    && chmod +x /ceph/src/script/lib-build.sh ) || true
RUN curl -LsS https://raw.githubusercontent.com/ceph/ceph/"$VCS_BRANCH"/ceph.spec.in \
    -o /ceph/ceph.spec.in

ARG FOR_MAKE_CHECK=1
ARG _SOURCED_LIB_BUILD=0
# This is required in squid and reef.
RUN if [[ "${VCS_BRANCH}" =~ ^(reef|squid)$ ]]; then \
    dnf install -y --skip-broken \  
        https://github.com/Seagate/cortx-motr/releases/download/2.0.0-rgw/isa-l-2.30.0-1.el7.x86_64.rpm \
        https://github.com/Seagate/cortx-motr/releases/download/2.0.0-rgw/cortx-motr-2.0.0-1_git3252d623_any.el8.x86_64.rpm \
        https://github.com/Seagate/cortx-motr/releases/download/2.0.0-rgw/cortx-motr-devel-2.0.0-1_git3252d623_any.el8.x86_64.rpm; \
    fi
RUN bash -x /ceph/install-deps.sh \
    && dnf clean packages

RUN dnf install -y ninja-build \
    && dnf clean packages

RUN dnf clean all && rm -rf /var/cache/dnf/*

COPY install-node.sh /root
RUN /root/install-node.sh
