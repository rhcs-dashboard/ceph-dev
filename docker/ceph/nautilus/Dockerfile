FROM centos:7

RUN yum install -y bind-utils centos-release-scl curl epel-release iputils net-tools yum yum-utils \
    && yum clean all

RUN yum install -y ant apache-commons-cli batik blender-rpm-macros blis-srpm-macros boost-random btrfs-progs bzip2 \
    ccache cmake cmake3 cryptsetup CUnit-devel Cython \
    devtoolset-8-gcc-c++ doxygen epel-rpm-macros erlang-rpm-macros expat-devel \
    fuse-devel gcc-c++ ghc-rpm-macros git gperf gperftools-devel graphviz \
    iproute java-1.8.0-openjdk-devel \
    jq junit keyutils-libs-devel kf5-rpm-macros leveldb-devel libaio-devel libbabeltrace-devel libblkid-devel \
    libcurl-devel libnl3-devel liboath-devel librabbitmq-devel librdkafka librdkafka-devel libtool libtool-ltdl-devel libuuid-devel libxml2-devel \
    lttng-ust-devel lz4-devel mailcap ncurses-devel nss-devel \
    ocaml-srpm-macros openblas-srpm-macros openldap-devel openssl-devel parted \
    python-cherrypy python-coverage python-devel python-jwt python-nose python-pecan \
    python-prettytable python-qt5-rpm-macros python-requests python-routes python-sphinx python-tox \
    python-virtualenv python-werkzeug python2-bcrypt python2-pip python2-rpm-macros \
    python3-other-rpm-macros python36-Cython python36-devel python36-setuptools \
    qt5-rpm-macros \
    rdma-core-devel redhat-lsb-core redhat-rpm-config selinux-policy-devel \
    selinux-policy-doc sharutils snappy-devel socat \
    systemd-devel sudo valgrind-devel xfsprogs xfsprogs-devel xmlsec1 xmlsec1-devel xmlsec1-nss \
    xmlsec1-openssl xmlsec1-openssl-devel xmlstarlet yasm wget \
    && yum clean all

# Required to enable debug repos and install python debug packages
RUN debuginfo-install -y python && yum clean all

# Install doc-build deps
RUN wget "https://kojipkgs.fedoraproject.org//packages/jericho-html/3.2/5.fc19/noarch/jericho-html-3.2-5.fc19.noarch.rpm" \
      "https://kojipkgs.fedoraproject.org//packages/ditaa/0.9/10.r74.fc20/noarch/ditaa-0.9-10.r74.fc20.noarch.rpm" && \
      rpm -vih jericho-html-3.2-5.fc19.noarch.rpm ditaa-0.9-10.r74.fc20.noarch.rpm

RUN sed -i 's/LIBLTDL=1 -I/LIBLTDL=1 -DXMLSEC_NO_SIZE_T -I/' /usr/bin/xmlsec1-config

RUN pip install -U pip \
    && pip install python-saml==2.4.2 tox==2.9.1

COPY e2e/google-chrome.repo /etc/yum.repos.d

RUN yum install -y google-chrome-stable && yum clean all

# AWS CLI.
RUN yum install -y awscli \
    && yum clean all
COPY aws/aws-cli-configure.sh /root
RUN /root/aws-cli-configure.sh

RUN yum-config-manager --save --setopt=\*.skip_if_unavailable=true \*

RUN rm -rf /var/cache/yum/*

RUN mkdir /ceph

WORKDIR /ceph

ENV PATH="/opt/rh/devtoolset-8/root/usr/bin:$PATH"
