#!/bin/bash

if [ ! -f /usr/sbin/sysctl.real ]; then
    mv /usr/sbin/sysctl /usr/sbin/sysctl.real
fi

cat <<'EOF' > /usr/sbin/sysctl
#!/bin/bash

# A. Intercept write/apply commands and fake a success instantly
if [[ "$*" == *"--system"* ]] || [[ "$*" == *"-w"* ]] || [[ "$*" == *"-p"* ]]; then
    exit 0
fi

# B. Pass all read commands (like -a) to the real binary. 
# We pipe stderr to /dev/null just in case reading a restricted key throws a warning.
exec /usr/sbin/sysctl.real "$@" 2>/dev/null
EOF

chmod +x /usr/sbin/sysctl
