FROM fedora:29

RUN dnf install -y bind-utils curl dnf dnf-plugins-core iputils net-tools && dnf clean all

RUN dnf install -y ant apache-commons-cli batik boost-random btrfs-progs bzip2 ccache cmake cmake3 cryptsetup \
    CUnit-devel Cython ditaa doxygen expat-devel fuse-devel gcc-c++ git gperf gperftools-devel graphviz \
    jericho-html iproute java-1.8.0-openjdk-devel \
    jq junit keyutils-libs-devel leveldb-devel libaio-devel libbabeltrace-devel libblkid-devel \
    libcurl-devel liboath-devel librabbitmq-devel libtool libtool-ltdl-devel \
    libuuid-devel libxml2-devel lttng-ust-devel lz4-devel mailcap ncurses-devel \
    nss-devel openldap-devel openssl-devel parted perl \
    python3-cherrypy python3-coverage python3-jwt python3-nose python3-pecan python3-prettytable \
    python3-requests python3-routes python3-sphinx python3-tox python3-virtualenv python3-werkzeug \
    python3-bcrypt python3-pip python3-saml python3-Cython python3-devel python3-setuptools \
    rdma-core-devel redhat-lsb-core redhat-rpm-config selinux-policy-devel selinux-policy-doc \
    sharutils snappy-devel socat \
    systemd-devel sudo valgrind-devel xfsprogs xfsprogs-devel xmlsec1 xmlsec1-devel xmlsec1-nss \
    xmlsec1-openssl xmlsec1-openssl-devel xmlstarlet yasm wget \
    && dnf clean all

# Required to enable debug repos and install python debug packages
RUN dnf debuginfo-install -y python3 && dnf clean all

# Required in order for build-doc to check the appropriate dependencies:
RUN dnf remove -y dnf-yum && dnf clean all
# Required in order for build-doc to run successfully:
RUN pip3 install -U Cython==0.29.3

COPY e2e/google-chrome.repo /etc/yum.repos.d
RUN dnf install -y google-chrome-stable && dnf clean all

RUN dnf config-manager --save --setopt=\*.skip_if_unavailable=true \*

RUN rm -rf /var/cache/dnf/*

RUN mkdir /ceph

WORKDIR /ceph

ENV PATH="/usr/libexec/python3-sphinx:$PATH"
