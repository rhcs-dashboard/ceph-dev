ARG CENTOS_VERSION=8
FROM centos:$CENTOS_VERSION as ceph-base
ARG CENTOS_VERSION

RUN dnf install -y epel-release \
    && dnf clean packages
RUN dnf install -y bind-utils curl dnf dnf-plugins-core git hostname iputils jq lsof net-tools python3-pip \
    util-linux which python3-jsonpatch \
    && dnf clean packages

RUN sed -i 's/gpgcheck=1/gpgcheck=0/' /etc/dnf/dnf.conf
RUN sed -i 's/skip_if_unavailable=False/skip_if_unavailable=True/' /etc/dnf/dnf.conf

RUN dnf config-manager --set-enabled powertools

RUN pip3 install -U pip

# Sanity checks:
RUN pip3 install mypy tox

# AWS CLI.
RUN pip3 install awscli boto3 boto3-stubs
COPY aws/aws-cli-configure.sh /root
RUN /root/aws-cli-configure.sh

# For dev mode: node installation tool.
RUN pip3 install nodeenv

# For dev. mode: run e2e tests.
RUN dnf install -y https://dl.google.com/linux/direct/google-chrome-stable_current_x86_64.rpm \
    libXScrnSaver xorg-x11-server-Xvfb \
    && dnf clean packages

# SSO deps (install before fedora provisional deps).
RUN dnf install -y gcc-c++ make \
    && dnf clean packages

# For dev. mode: run backend unit tests.
# Fedora provide missing dependencies for backend unit tests until epel provide all dependencies.
#COPY fedora/fedora.repo /etc/yum.repos.d
RUN dnf install -y libtool-ltdl-devel libxml2-devel python36-devel xmlsec1-devel xmlsec1-openssl-devel \
    && dnf clean packages
#RUN dnf config-manager --set-disabled fedora

# SSO (after installing xmlsec deps).
RUN pip3 install python3-saml==1.9.0

# NFS Ganesha.
RUN dnf install -y centos-release-nfs-ganesha30 \
    && dnf install -y nfs-ganesha-rados-grace nfs-ganesha-rados-urls \
    && dnf clean packages

# S3 benchmark:
RUN dnf install -y go \
    && go get github.com/markhpc/hsbench && cd /root/go/src/github.com/markhpc/hsbench \
    && go build && mv hsbench /usr/local/bin/hsbench \
    && dnf remove -y go && rm -rf /root/go && dnf clean packages

RUN dnf clean all && rm -rf /var/cache/dnf/*

RUN mkdir -p /ceph/build /ceph/src

WORKDIR /ceph
