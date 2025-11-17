ARG CENTOS_VERSION=9
ARG TARGETPLATFORM
ARG TARGETARCH

FROM quay.io/centos/centos:stream$CENTOS_VERSION as ceph-base

ARG TARGETARCH
ARG CENTOS_VERSION
ENV TARGETARCH=$TARGETARCH

RUN dnf install -y epel-release \
    && dnf clean packages
RUN dnf install -y bind-utils dnf dnf-plugins-core git golang-github-prometheus hostname \
    iproute iputils jq jsonnet lsof net-tools procps-ng \
    python3-jinja2 python3-jsonpatch python3-pip util-linux which \
    && dnf clean packages

RUN dnf config-manager --set-enabled crb
RUN dnf distro-sync -y

RUN sed -i 's/gpgcheck=1/gpgcheck=0/' /etc/dnf/dnf.conf
RUN sed -i 's/skip_if_unavailable=False/skip_if_unavailable=True/' /etc/dnf/dnf.conf

RUN pip3 install -U pip

# Sanity checks:
# pinning tox to less than 4 since newer versions of it
# is breaking it in py3.9
RUN pip3 install mypy 'tox<4'

# AWS CLI.
RUN pip3 install awscli boto3 boto3-stubs
COPY aws/aws-cli-configure.sh /root
RUN /root/aws-cli-configure.sh

# For dev mode: node installation tool.
RUN pip3 install nodeenv

# For dev. mode: run e2e tests.
RUN if [ "$TARGETARCH" = "amd64" ]; then \
    dnf install -y https://dl.google.com/linux/direct/google-chrome-stable_current_x86_64.rpm \
        libXScrnSaver xorg-x11-server-Xvfb \
        && dnf clean packages; \
    fi

# SSO deps (install before fedora provisional deps).
RUN dnf install -y gcc-c++ make \
    && dnf clean packages

# Fedora provide missing dependencies until epel provide all dependencies.
COPY fedora/fedora.repo /etc/yum.repos.d
RUN dnf install -y ditaa \
    && dnf clean packages
RUN dnf config-manager --set-disabled fedora

# Install doc-build deps.
RUN dnf install -y ant doxygen libxslt-devel libxml2-devel graphviz python3-devel python3-pip python3-virtualenv \
    python3-Cython \
    && dnf clean packages

# Conflicting versions of virtualenv causes issues with tox.
RUN pip3 uninstall -y virtualenv
RUN pip3 install virtualenv

RUN dnf install -y centos-release-nfs-ganesha5 centos-release-ceph-reef \
    && dnf install -y libcephfs2 nfs-ganesha-ceph nfs-ganesha-rados-grace nfs-ganesha-rados-urls \
    && dnf clean packages

# S3 benchmark:
RUN dnf install -y golang \
    && go install github.com/markhpc/hsbench@latest && mv /root/go/bin/hsbench /usr/local/bin/hsbench \
    && dnf remove -y golang && rm -rf /root/go \
    && dnf clean packages

RUN dnf clean all && rm -rf /var/cache/dnf/*

RUN mkdir -p /ceph/build /ceph/src

WORKDIR /ceph
