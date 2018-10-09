FROM centos:7

RUN curl -LsS https://rpm.nodesource.com/setup_8.x | bash -

RUN yum install -y nodejs && yum clean all

RUN yum install -y centos-release-scl epel-release && yum clean all

RUN yum install -y boost-random btrfs-progs bzip2 ccache cmake3 cryptsetup CUnit-devel Cython \
    devtoolset-7 expat-devel fuse-devel gcc-c++ git gperf gperftools-devel iproute java-1.8.0-openjdk-devel \
    jq junit keyutils-libs-devel leveldb-devel libaio-devel libbabeltrace-devel libblkid-devel \
    libcurl-devel liboath-devel libtool libuuid-devel libxml2-devel lttng-ust-devel lz4-devel mailcap \
    net-tools nss-devel openldap-devel openssl-devel parted python-cherrypy python-coverage python-devel \
    python-nose python-pecan python-prettytable python-requests \
    python-routes python-sphinx python-tox python-virtualenv python-werkzeug \
    python2-bcrypt python34-Cython python34-devel python34-setuptools rdma-core-devel \
    redhat-lsb-core redhat-rpm-config selinux-policy-devel sharutils snappy-devel socat \
    systemd-devel sudo valgrind-devel xfsprogs xfsprogs-devel xmlstarlet yasm yum-utils wget \
    && yum clean all

ENV PATH="/opt/rh/devtoolset-7/root/usr/bin:$PATH"
ENV PYTHONDONTWRITEBYTECODE="1"

# To increase ccache hit rate
ENV SOURCE_DATE_EPOCH="358228200"
ENV BUILD_DATE="1981-05-09"
ENV CCACHE_SLOPPINESS="file_macro,file_stat_matches,include_file_ctime,include_file_mtime,no_system_headers,pch_defines"
ENV CCACHE_MAXSIZE="20G"

RUN wget https://github.com/prometheus/node_exporter/releases/download/v0.16.0/node_exporter-0.16.0.linux-amd64.tar.gz \
    && tar -xzvf node_exporter-0.16.0.linux-amd64.tar.gz \
    && mv node_exporter-0.16.0.linux-amd64 /opt/node_exporter

RUN mkdir /ceph

WORKDIR /ceph
