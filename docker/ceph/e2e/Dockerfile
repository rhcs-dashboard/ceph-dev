ARG CENTOS_VERSION=8
FROM quay.io/centos/centos:stream$CENTOS_VERSION

RUN dnf --disablerepo '*' --enablerepo=extras swap centos-linux-repos centos-stream-repos -y
RUN dnf distro-sync -y

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
ARG VCS_BRANCH=main
COPY install-node.sh /root
RUN /root/install-node.sh
