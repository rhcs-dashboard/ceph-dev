FROM centos:7

RUN yum install -y bind-utils curl epel-release iputils net-tools yum yum-utils \
    && yum clean all

RUN yum install -y jq && yum clean all

# For dev. purposes (compile frontend app into 'dist' directory)
RUN yum install -y bzip2 gcc-c++ make python2-pip \
    && yum clean all \
    && pip install nodeenv \
    && nodeenv venv -n 8.10.0
RUN ln -s /venv/bin/node /usr/local/bin/node \
    && ln -s /venv/bin/npm /usr/local/bin/npm \
    && ln -s /venv/bin/npx /usr/local/bin/npx
COPY e2e/google-chrome.repo /etc/yum.repos.d
RUN yum install -y google-chrome-stable && yum clean all

ARG REPO_URL=https://download.ceph.com/rpm-mimic/el7/x86_64/
ARG VCS_BRANCH=v13.2.5

RUN printf "[mimic]\nname=Ceph Mimic\nbaseurl=$REPO_URL\nenabled=1\ngpgcheck=0" > /etc/yum.repos.d/ceph.repo

RUN yum install -y ceph-mds ceph-mgr ceph-mon ceph-osd ceph-radosgw && yum clean all

RUN mkdir -p /ceph/build /ceph/src

RUN curl -LsS https://raw.githubusercontent.com/ceph/ceph/"$VCS_BRANCH"/src/vstart.sh \
    -o /ceph/src/vstart.sh \
    && chmod +x /ceph/src/vstart.sh

RUN rm -rf /var/cache/yum/*

WORKDIR /ceph
