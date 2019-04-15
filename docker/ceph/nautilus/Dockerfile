FROM centos:7

RUN yum install -y bind-utils curl epel-release iputils net-tools yum yum-utils \
    && yum clean all

RUN yum install -y jq && yum clean all

COPY nautilus/nautilus.repo /etc/yum.repos.d

RUN yum install -y ceph ceph-mgr-dashboard ceph-radosgw && yum clean all

RUN mkdir -p /ceph/build /ceph/src

RUN curl -LsS https://raw.githubusercontent.com/ceph/ceph/v14.2.0/src/vstart.sh \
    -o /ceph/src/vstart.sh \
    && chmod +x /ceph/src/vstart.sh

# For dev. purposes (compile frontend app into 'dist' directory)
RUN yum install -y gcc-c++ git python2-pip \
    && yum clean all \
    && pip install nodeenv \
    && nodeenv venv -n 10.13.0
RUN ln -s /venv/bin/node /usr/local/bin/node \
    && ln -s /venv/bin/npm /usr/local/bin/npm \
    && ln -s /venv/bin/npx /usr/local/bin/npx

RUN rm -rf /var/cache/yum/*

WORKDIR /ceph
