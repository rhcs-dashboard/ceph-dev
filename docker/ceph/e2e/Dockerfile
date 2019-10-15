FROM fedora

ARG NODE_VERSION=10.13.0

RUN pip3 install -U nodeenv \
    && nodeenv venv -n "${NODE_VERSION}"
RUN ln -s /venv/bin/node /usr/local/bin/node \
    && ln -s /venv/bin/npm /usr/local/bin/npm \
    && ln -s /venv/bin/npx /usr/local/bin/npx

RUN dnf install -y https://dl.google.com/linux/direct/google-chrome-stable_current_x86_64.rpm \
    && dnf clean all

RUN rm -rf /var/cache/dnf/*

RUN mkdir /ceph /e2e

WORKDIR /ceph

COPY e2e-run.sh /e2e

ENTRYPOINT ["/e2e/e2e-run.sh"]
