#!/bin/bash

mv /usr/bin/podman /usr/bin/podman.real && \
    cat <<'EOF' > /usr/bin/podman
#!/bin/bash
intercepted_execution_arguments=("$@")

# Prevent network pulls if the image is already cached locally
if [[ "${intercepted_execution_arguments[0]}" == "pull" ]]; then

    # Iterate through arguments to find the target container image reference
    for current_argument_string in "${intercepted_execution_arguments[@]}"; do

        # Ignore the 'pull' command itself and any flags (like --quiet or --tls-verify)
        if [[ "$current_argument_string" != -* && "$current_argument_string" != "pull" ]]; then

            # Utilize native Podman validation to check the local registry cache
            if /usr/bin/podman.real image exists "$current_argument_string"; then
                echo "[Podman Intercept]: Target container image reference '$current_argument_string' is already cached locally. Bypassing network operation."
                exit 0
            fi

        fi
    done
fi

exec /usr/bin/podman.real "${intercepted_execution_arguments[@]}"
EOF

chmod +x /usr/bin/podman
