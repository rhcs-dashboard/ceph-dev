FROM centos:7

RUN yum install -y centos-release-scl epel-release && yum clean all

RUN yum install -y boost-random btrfs-progs bzip2 ccache cmake cryptsetup CUnit-devel Cython \
    devtoolset-7 expat-devel fuse-devel git gperf gperftools-devel iproute java-1.8.0-openjdk-devel \
    jq junit keyutils-libs-devel leveldb-devel libaio-devel libbabeltrace-devel libblkid-devel \
    libcurl-devel liboath-devel libtool libuuid-devel libxml2-devel lttng-ust-devel lz4-devel mailcap \
    net-tools nss-devel openldap-devel openssl-devel parted python-cherrypy python-coverage python-devel \
    python-nose python-pecan python-prettytable python-requests \
    python-routes python-sphinx python-tox python-virtualenv python-werkzeug \
    python2-bcrypt python34-Cython python34-devel python34-setuptools rdma-core-devel \
    redhat-lsb-core redhat-rpm-config selinux-policy-devel sharutils snappy-devel socat \
    systemd-devel valgrind-devel xfsprogs xfsprogs-devel xmlstarlet yasm \
    && yum clean all

ENV PATH="/opt/rh/devtoolset-7/root/usr/bin:$PATH"

RUN curl -LsS https://rpm.nodesource.com/setup_8.x | bash -

RUN yum install -y nodejs && yum clean all

RUN mkdir /ceph

WORKDIR /ceph
