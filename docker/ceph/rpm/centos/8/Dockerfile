FROM centos:8 AS ceph-rpm-base-centos8

RUN dnf install -y bind-utils curl dnf dnf-plugins-core hostname iputils jq lsof net-tools python3-pip \
    && dnf clean all

RUN dnf config-manager --save --setopt=\*.skip_if_unavailable=true \*

# AWS CLI.
RUN pip3 install awscli \
    && dnf clean all
COPY aws/aws-cli-configure.sh /root
RUN /root/aws-cli-configure.sh

# For dev. mode: run e2e tests.
RUN dnf install -y https://dl.google.com/linux/direct/google-chrome-stable_current_x86_64.rpm \
    && dnf clean all