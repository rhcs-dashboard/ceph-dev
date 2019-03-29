FROM fedora:29

RUN dnf install -y bind-utils curl dnf dnf-plugins-core hostname iputils jq lsof net-tools \
    && dnf clean all

COPY rpm/ceph-rpm.repo /etc/yum.repos.d

RUN dnf install -y ceph ceph-mgr-dashboard ceph-radosgw \
    && dnf clean all

RUN mkdir -p /ceph/build /ceph/src

RUN curl -LsS https://raw.githubusercontent.com/ceph/ceph/master/src/vstart.sh \
    -o /ceph/src/vstart.sh \
    && chmod +x /ceph/src/vstart.sh

WORKDIR /ceph

# For dev. purposes (compile frontend app into 'dist' directory)
RUN dnf install -y gcc-c++ git \
    && dnf clean all
RUN pip3 install -U nodeenv pip tox \
    && nodeenv venv -n 10.13.0

RUN rm -rf /var/cache/dnf/*
