#!/bin/bash

# missing dir for cephadm
mkdir -p /run/udev/data
mkdir -p /dev/cpu

rm -rf /etc/sysctl.d
mkdir -p /etc/sysctl.d

# spoofing time for chrony service
if [ ! -f "/usr/bin/systemctl.real" ]; then
    mv /usr/bin/systemctl /usr/bin/systemctl.real
fi

cat <<'EOF' > /usr/bin/systemctl
#!/bin/bash
args=("$@")
TIME_DAEMONS=("chronyd" "chrony.service" "chrony" "systemd-timesyncd" "ntpd" "ntp" "timemaster")

for arg in "${args[@]}"; do
    for daemon in "${TIME_DAEMONS[@]}"; do
        if [[ "$arg" == *"$daemon"* ]]; then
            if [[ "${args[0]}" == "is-active" || "${args[0]}" == "status" ]]; then
                echo "active"
                exit 0
            fi
            exit 0
        fi
    done
done

exec /usr/bin/systemctl.real "${args[@]}"
EOF

chmod +x /usr/bin/systemctl

ssh-keygen -A
systemctl enable sshd
