FROM centos:7

RUN yum install -y epel-release yum-utils && yum clean all

RUN yum install -y curl jq net-tools && yum clean all

RUN curl -LsS -o node_exporter.tar.gz \
    https://github.com/prometheus/node_exporter/releases/download/v0.16.0/node_exporter-0.16.0.linux-amd64.tar.gz \
    && mkdir /opt/node_exporter \
    && tar -xzvf node_exporter.tar.gz --strip 1 -C /opt/node_exporter \
    && rm node_exporter.tar.gz

COPY luminous.repo /etc/yum.repos.d

RUN yum install -y ceph-mds ceph-mgr ceph-mon ceph-osd ceph-radosgw && yum clean all

RUN mkdir -p /ceph/build /ceph/src

RUN curl -LsS https://github.com/ceph/ceph/raw/v12.2.8/src/vstart.sh \
    -o /ceph/src/vstart.sh \
    && chmod +x /ceph/src/vstart.sh

WORKDIR /ceph
