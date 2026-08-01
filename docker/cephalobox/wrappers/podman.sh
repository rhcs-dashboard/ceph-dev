#!/bin/bash

mv /usr/bin/podman /usr/bin/podman.real && \
    cat <<'EOF' > /usr/bin/podman
#!/bin/bash
args=("$@")

# Prevent network pulls if the image is already cached locally
if [[ "${args[0]}" == "pull" ]]; then
    for arg in "${args[@]}"; do
        if [[ "$arg" == *"quay.ceph.io/ceph-ci/ceph"* ]]; then
            if /usr/bin/podman.real images -q "$arg" | grep -q .; then 
                echo "Fake pull successful. Image already cached locally."
                exit 0
            fi
        fi
    done
fi

exec /usr/bin/podman.real "${args[@]}"
EOF

chmod +x /usr/bin/podman
