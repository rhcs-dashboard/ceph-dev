FROM centos:7

RUN yum install -y bind-utils curl epel-release iputils net-tools yum yum-utils \
    && yum clean all

RUN yum install -y jq && yum clean all

COPY mimic/mimic.repo /etc/yum.repos.d

RUN yum install -y ceph-mds ceph-mgr ceph-mon ceph-osd ceph-radosgw && yum clean all

RUN mkdir -p /ceph/build /ceph/src

RUN curl -LsS https://raw.githubusercontent.com/ceph/ceph/v13.2.5/src/vstart.sh \
    -o /ceph/src/vstart.sh \
    && chmod +x /ceph/src/vstart.sh

WORKDIR /ceph

# For dev. purposes (compile frontend app into 'dist' directory)
RUN yum install -y bzip2 gcc-c++ make python2-pip \
    && yum clean all \
    && pip install nodeenv \
    && nodeenv venv -n 8.10.0

RUN rm -rf /var/cache/yum/*
