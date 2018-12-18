FROM centos:7

RUN yum install -y centos-release-scl deltarpm epel-release && yum clean all

RUN yum install -y boost-random btrfs-progs bzip2 ccache cmake cmake3 cryptsetup CUnit-devel Cython \
    devtoolset-7-gcc-c++ expat-devel fuse-devel gcc-c++ git gperf gperftools-devel iproute java-1.8.0-openjdk-devel \
    jq junit keyutils-libs-devel leveldb-devel libaio-devel libbabeltrace-devel libblkid-devel \
    libcurl-devel liboath-devel libtool libtool-ltdl-devel libuuid-devel libxml2-devel lttng-ust-devel lz4-devel mailcap \
    net-tools nss-devel openldap-devel openssl-devel parted python-cherrypy python-coverage python-devel \
    python-jwt python-nose python-pecan python-prettytable python-requests \
    python-routes python-sphinx python-tox python-virtualenv python-werkzeug \
    python2-bcrypt python2-pip python34-Cython python34-devel python34-setuptools rdma-core-devel \
    redhat-lsb-core redhat-rpm-config selinux-policy-devel selinux-policy-doc sharutils snappy-devel socat \
    systemd-devel sudo valgrind-devel xfsprogs xfsprogs-devel xmlsec1 xmlsec1-devel xmlsec1-nss \
    xmlsec1-openssl xmlsec1-openssl-devel xmlstarlet yasm yum-utils wget \
    && yum clean all

RUN sed -i 's/LIBLTDL=1 -I/LIBLTDL=1 -DXMLSEC_NO_SIZE_T -I/' /usr/bin/xmlsec1-config

RUN pip install -U pip \
    && pip install python-saml==2.4.2 tox==2.9.1

COPY e2e/google-chrome.repo /etc/yum.repos.d

RUN yum install -y google-chrome-stable && yum clean all

#RUN curl -LsS -o nodejs.tar.xz \
#    https://nodejs.org/dist/v10.13.0/node-v10.13.0-linux-x64.tar.xz \
#    && mkdir /opt/nodejs \
#    && tar -xJvf nodejs.tar.xz --strip 1 -C /opt/nodejs \
#    && rm nodejs.tar.xz \
#    && ln -s /opt/nodejs/bin/node /usr/bin/node && ln -s /opt/nodejs/bin/npm /usr/bin/npm

RUN yum-config-manager --save --setopt=\*.skip_if_unavailable=true \*

RUN rm -rf /var/cache/yum/*

RUN mkdir /ceph

WORKDIR /ceph

ENV PATH="/opt/rh/devtoolset-7/root/usr/bin:/ceph/build/src/pybind/mgr/dashboard/node-env/bin:$PATH"
ENV PYTHONDONTWRITEBYTECODE="1"

# To increase ccache hit rate
ENV SOURCE_DATE_EPOCH="358228200"
ENV BUILD_DATE="1981-05-09"
