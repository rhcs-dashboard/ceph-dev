FROM centos:7

RUN yum install -y bind-utils curl epel-release iputils net-tools yum yum-utils \
    && yum clean all

RUN yum install -y jq && yum clean all

COPY mimic.repo /etc/yum.repos.d

RUN yum install -y ceph-mds ceph-mgr ceph-mon ceph-osd ceph-radosgw && yum clean all

RUN mkdir -p /ceph/build /ceph/src

RUN curl -LsS https://raw.githubusercontent.com/ceph/ceph/v13.2.5/src/vstart.sh \
    -o /ceph/src/vstart.sh \
    && chmod +x /ceph/src/vstart.sh

WORKDIR /ceph
