FROM registry.access.redhat.com/ubi8

RUN dnf install -y bind-utils curl dnf dnf-plugins-core hostname iputils lsof net-tools python36 \
    && dnf clean all

COPY rpm/rhel/fedora.repo /etc/yum.repos.d
RUN dnf install -y jq \
    && dnf clean all

# For dev mode: compile frontend app into 'dist' directory.
RUN dnf install -y gcc-c++ git \
    && dnf clean all
RUN pip3 install -U nodeenv pip tox \
    && nodeenv venv -n 10.16.0
RUN ln -s /venv/bin/node /usr/local/bin/node \
    && ln -s /venv/bin/npm /usr/local/bin/npm \
    && ln -s /venv/bin/npx /usr/local/bin/npx

# For dev. mode: run integration tests.
RUN dnf install -y python2-devel redhat-rpm-config \
    && dnf clean all

ARG REPO_URL
COPY rpm/set-ceph-repo.sh /root
RUN /root/set-ceph-repo.sh

RUN dnf install -y ceph ceph-fuse ceph-mgr-dashboard ceph-radosgw \
    && dnf clean all

RUN rm -rf /var/cache/dnf/*

RUN mkdir -p /ceph/build /ceph/src

ARG VCS_BRANCH=master
RUN curl -LsS https://raw.githubusercontent.com/ceph/ceph/"$VCS_BRANCH"/src/vstart.sh \
    -o /ceph/src/vstart.sh \
    && chmod +x /ceph/src/vstart.sh

WORKDIR /ceph
