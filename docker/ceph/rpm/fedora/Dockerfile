FROM fedora:29

RUN dnf install -y bind-utils curl dnf dnf-plugins-core hostname iputils jq lsof net-tools \
    && dnf clean all

# For dev. purposes (compile frontend app into 'dist' directory)
RUN dnf install -y gcc-c++ git \
    && dnf clean all
RUN pip3 install -U nodeenv pip tox \
    && nodeenv venv -n 10.16.0
RUN ln -s /venv/bin/node /usr/local/bin/node \
    && ln -s /venv/bin/npm /usr/local/bin/npm \
    && ln -s /venv/bin/npx /usr/local/bin/npx

# For dev. mode: run integration tests.
RUN yum install -y python2-devel python2-pip \
    && yum clean all
RUN ln -sf /usr/bin/pip2 /usr/local/bin/pip

RUN dnf remove -y python-unversioned-command \
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
