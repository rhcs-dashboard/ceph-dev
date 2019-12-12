FROM fedora:29

RUN dnf install -y bind-utils curl dnf dnf-plugins-core hostname iputils jq lsof net-tools \
    && dnf clean all

RUN dnf install -y ant apache-commons-cli batik blender-rpm-macros blis-srpm-macros boost-random btrfs-progs bzip2 \
    ccache cmake cmake3 cryptsetup \
    CUnit-devel Cython ditaa doxygen erlang-rpm-macros expat-devel fedora-rpm-macros flatpak-rpm-macros fuse-devel \
    gcc-c++ ghc-rpm-macros git gperf gperftools-devel graphviz \
    jericho-html iproute java-1.8.0-openjdk-devel junit \
    kde-apps-rpm-macros kernel-rpm-macros keyutils-libs-devel kf5-rpm-macros \
    leveldb-devel libaio-devel libbabeltrace-devel libblkid-devel \
    libcurl-devel liboath-devel librabbitmq-devel librdkafka librdkafka-devel libtool libtool-ltdl-devel \
    libuuid-devel libxml2-devel lttng-ust-devel lz4-devel mailcap ncurses-devel \
    nss-devel openldap-devel openssl-devel parted perl postgresql-test-rpm-macros \
    python-qt5-rpm-macros \
    python3-cherrypy python3-coverage python3-jwt python3-nose python3-pecan python3-prettytable \
    python3-requests python3-routes python3-sphinx python3-tox python3-virtualenv python3-werkzeug \
    python3-bcrypt python3-pip python3-saml python3-Cython python3-devel python3-setuptools \
    qt5-rpm-macros \
    rdma-core-devel redhat-lsb-core redhat-rpm-config selinux-policy-devel selinux-policy-doc \
    sharutils snappy-devel socat \
    systemd-devel sudo typelib-srpm-macros valgrind-devel wget \
    xfsprogs xfsprogs-devel xmlsec1 xmlsec1-devel xmlsec1-nss \
    xmlsec1-openssl xmlsec1-openssl-devel xmlstarlet yasm \
    && dnf clean all

# Required to enable debug repos and install python debug packages
RUN dnf debuginfo-install -y python3 && dnf clean all

# Required in order for build-doc to check the appropriate dependencies:
RUN dnf remove -y dnf-yum && dnf clean all
# Required in order for build-doc to run successfully:
RUN pip3 install -U Cython==0.29.3
# Sanity checks:
RUN pip3 install mypy
COPY e2e/google-chrome.repo /etc/yum.repos.d
RUN dnf install -y google-chrome-stable && dnf clean all

# AWS CLI.
RUN dnf install -y awscli \
    && dnf clean all
COPY aws/aws-cli-configure.sh /root
RUN /root/aws-cli-configure.sh

RUN dnf config-manager --save --setopt=\*.skip_if_unavailable=true \*

RUN rm -rf /var/cache/dnf/*

RUN mkdir /ceph

WORKDIR /ceph

ENV PATH="/usr/libexec/python3-sphinx:$PATH"
