ARG CENTOS_VERSION=8
FROM centos:$CENTOS_VERSION

# Centos met EOL and the content of the CentOS 8 repos has been moved to vault.centos.org
RUN sed -i 's/mirrorlist/#mirrorlist/g' /etc/yum.repos.d/CentOS-Linux-*
RUN sed -i 's|#baseurl=http://mirror.centos.org|baseurl=http://vault.centos.org|g' /etc/yum.repos.d/CentOS-Linux-*

RUN dnf install -y https://dl.google.com/linux/direct/google-chrome-stable_current_x86_64.rpm \
    libXScrnSaver xorg-x11-server-Xvfb \
    && dnf clean all

RUN rm -rf /var/cache/dnf/*

RUN mkdir /ceph /e2e

WORKDIR /ceph

COPY e2e/e2e-run.sh /e2e

ENTRYPOINT ["/e2e/e2e-run.sh"]

RUN dnf install -y python3-pip \
    && dnf clean all
RUN pip3 install nodeenv
ARG VCS_BRANCH=master
COPY install-node.sh /root
RUN /root/install-node.sh
