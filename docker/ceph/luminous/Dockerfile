FROM centos:7

RUN yum install -y epel-release yum-utils && yum clean all

RUN yum install -y curl jq net-tools && yum clean all

RUN curl -LsS https://github.com/prometheus/node_exporter/releases/download/v0.16.0/node_exporter-0.16.0.linux-amd64.tar.gz \
    -o node_exporter-0.16.0.linux-amd64.tar.gz \
    && tar -xzvf node_exporter-0.16.0.linux-amd64.tar.gz \
    && rm node_exporter-0.16.0.linux-amd64.tar.gz \
    && mv node_exporter-0.16.0.linux-amd64 /opt/node_exporter

COPY luminous.repo /etc/yum.repos.d

RUN yum install -y ceph-mds ceph-mgr ceph-mon ceph-osd ceph-radosgw && yum clean all

RUN mkdir -p /ceph/build /ceph/src

RUN curl -LsS https://github.com/ceph/ceph/raw/v12.2.8/src/vstart.sh \
    -o /ceph/src/vstart.sh \
    && chmod +x /ceph/src/vstart.sh

WORKDIR /ceph
