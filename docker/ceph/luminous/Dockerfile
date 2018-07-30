FROM ceph-dev

RUN rpm --import https://download.ceph.com/keys/release.asc

RUN rpm -i https://download.ceph.com/rpm-luminous/el7/noarch/ceph-release-1-1.el7.noarch.rpm

RUN yum install -y ceph-mds ceph-mgr ceph-mon ceph-osd && yum clean all
