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

COPY nfs-ganesha/nfs-ganesha.repo /etc/yum.repos.d
RUN dnf install -y nfs-ganesha-ceph nfs-ganesha-rados-grace \
    && dnf clean packages

# For dev mode: compile frontend app into 'dist' directory.
RUN dnf install -y gcc-c++ make \
    && dnf clean packages
RUN pip3 install -U nodeenv \
    && nodeenv venv -n 10.16.0
RUN ln -s /venv/bin/node /usr/local/bin/node \
    && ln -s /venv/bin/npm /usr/local/bin/npm \
    && ln -s /venv/bin/npx /usr/local/bin/npx

# For dev. mode: run backend unit tests.
# Fedora provide missing dependencies for backend unit tests until epel provide all dependencies.
COPY fedora/fedora.repo /etc/yum.repos.d
RUN dnf install -y libtool-ltdl-devel libxml2-devel python36-devel xmlsec1-devel xmlsec1-openssl-devel \
    && dnf clean packages
RUN dnf config-manager --set-disabled fedora

RUN pip3 install python3-saml==1.9.0

# Sepia provide missing dependencies until epel provide all dependencies.
RUN dnf config-manager --add-repo http://apt-mirror.front.sepia.ceph.com/lab-extras/${CENTOS_VERSION}/
RUN dnf config-manager --setopt gpgcheck=0 apt-mirror.front.sepia.ceph.com_lab-extras_${CENTOS_VERSION}_ --save
RUN dnf copr enable -y ktdreyer/ceph-el${CENTOS_VERSION}

RUN sed -i 's/gpgcheck=1/gpgcheck=0/' /etc/dnf/dnf.conf

ARG REPO_URL
ARG CEPH_RELEASE=octopus
COPY rpm/set-ceph-repo.sh /root
RUN /root/set-ceph-repo.sh
RUN dnf install -y ceph ceph-mgr-dashboard ceph-mgr-diskprediction-local ceph-radosgw rbd-mirror \
    && dnf clean all

RUN rm -rf /var/cache/dnf/*

RUN mkdir -p /ceph/build /ceph/src

WORKDIR /ceph

ARG VCS_BRANCH=octopus
RUN curl -LsS https://raw.githubusercontent.com/ceph/ceph/"$VCS_BRANCH"/src/vstart.sh \
    -o /ceph/src/vstart.sh \
    && chmod +x /ceph/src/vstart.sh
