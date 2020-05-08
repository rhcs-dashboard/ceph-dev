ARG CENTOS_VERSION=8
FROM centos:$CENTOS_VERSION as ceph-base
ARG CENTOS_VERSION

RUN dnf install -y epel-release \
    && dnf clean packages
RUN dnf install -y bind-utils curl dnf dnf-plugins-core git hostname iputils jq lsof net-tools python3-pip \
    util-linux which \
    && dnf clean packages

RUN dnf config-manager --save --setopt=\*.skip_if_unavailable=true \*
RUN dnf config-manager --set-enabled PowerTools

RUN pip3 install -U pip

# Sanity checks:
RUN pip3 install mypy tox

# AWS CLI.
RUN pip3 install awscli
COPY aws/aws-cli-configure.sh /root
RUN /root/aws-cli-configure.sh

# For dev mode: node installation tool.
RUN pip3 install nodeenv

# For dev. mode: run e2e tests.
RUN dnf install -y https://dl.google.com/linux/direct/google-chrome-stable_current_x86_64.rpm \
    xorg-x11-server-Xvfb \
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

# For dev. mode: py2 is needed to run API tests until teuthology is py3 compatible.
RUN dnf install -y python2-devel \
    && dnf clean packages

COPY nfs-ganesha/nfs-ganesha.repo /etc/yum.repos.d
RUN dnf install -y nfs-ganesha-ceph nfs-ganesha-rados-grace \
    && dnf clean packages

RUN dnf clean all && rm -rf /var/cache/dnf/*

RUN mkdir -p /ceph/build /ceph/src

WORKDIR /ceph
