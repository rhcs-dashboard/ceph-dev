FROM almalinux:9

RUN dnf install -y epel-release && \
    dnf install -y python3 podman lvm2 \
        systemd openssh-server openssh-clients \
        nano procps-ng crun skopeo util-linux \
        iproute iptables iptables-nft which

# to prevent port conflict with host
RUN mkdir -p /root/.ssh && \
    echo -e "Host *\n    StrictHostKeyChecking no\n" > /root/.ssh/config && \
    sed -i 's/^#PermitRootLogin.*/PermitRootLogin yes/' /etc/ssh/sshd_config

COPY ceph-image.tar /opt/ceph-image.tar

COPY wrappers/ /opt/wrappers/

COPY cephalobox.service /etc/systemd/system/cephalobox.service
COPY cephalobox.py /usr/local/bin/cephalobox.py
COPY cephalobox.sh /usr/local/bin/cephalobox.sh
COPY osd.sh /usr/local/bin/osd.sh

RUN chmod +x /opt/wrappers/.
RUN chmod +x /usr/local/bin/cephalobox.py /usr/local/bin/cephalobox.sh /usr/local/bin/osd.sh

RUN bash /opt/wrappers/podman.sh
RUN bash /opt/wrappers/logger.sh
RUN bash /opt/wrappers/environment.sh

RUN systemctl enable cephalobox.service

CMD ["/sbin/init"]
