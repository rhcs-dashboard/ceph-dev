#!/bin/bash

mkdir -p /etc/containers && \
    cat <<'EOF' > /etc/containers/containers.conf
[engine]
events_logger = "none"
EOF

cat <<'EOF' > /etc/systemd/system/ceph-log-bridge.service
[Unit]
Description=Bridge Filtered Ceph Logs to Podman Console
After=systemd-journald.service

[Service]
Type=simple
# We use --line-buffered so logs stream instantly instead of waiting for a chunk
ExecStart=/bin/sh -c 'exec journalctl -f | grep --line-buffered -iE "cephadm|mgr|bootstrap|cephalobox|python" > /dev/console'
Restart=always

[Install]
WantedBy=multi-user.target
EOF

systemctl enable ceph-log-bridge.service