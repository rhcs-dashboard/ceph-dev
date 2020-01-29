ARG CENTOS_VERSION=8
FROM centos:$CENTOS_VERSION
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

# For dev. mode: run e2e tests.
RUN dnf install -y https://dl.google.com/linux/direct/google-chrome-stable_current_x86_64.rpm \
    && dnf clean packages

# For dev. mode: py2 is needed to run API tests until teuthology is py3 compatible.
RUN dnf install -y python2-devel \
    && dnf clean packages

# Required in order for build-doc to run successfully:
RUN pip3 install -U Cython==0.29.3

RUN mkdir /ceph

WORKDIR /ceph

ARG VCS_BRANCH=master
RUN curl -LsS https://raw.githubusercontent.com/ceph/ceph/"$VCS_BRANCH"/install-deps.sh \
    -o /ceph/install-deps.sh \
    && chmod +x /ceph/install-deps.sh
RUN curl -LsS https://raw.githubusercontent.com/ceph/ceph/"$VCS_BRANCH"/ceph.spec.in \
    -o /ceph/ceph.spec.in

RUN sed -i 's/gpgcheck=1/gpgcheck=0/' /etc/dnf/dnf.conf

ARG FOR_MAKE_CHECK=1
RUN bash -x /ceph/install-deps.sh \
    && dnf clean packages

# Install doc-build deps.
# Fedora provide missing dependencies until epel provide all dependencies.
COPY fedora/fedora.repo /etc/yum.repos.d
RUN dnf install -y ditaa \
    && dnf clean packages
RUN dnf config-manager --set-disabled fedora
RUN dnf install -y ant doxygen \
    && dnf clean all

RUN rm -rf /var/cache/dnf/*
