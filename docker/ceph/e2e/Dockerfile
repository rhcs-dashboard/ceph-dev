ARG CENTOS_VERSION=8
FROM centos:$CENTOS_VERSION

RUN dnf install -y https://dl.google.com/linux/direct/google-chrome-stable_current_x86_64.rpm \
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
