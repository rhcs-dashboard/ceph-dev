#!/usr/bin/env python3
import os
import sys
import subprocess
import socket

SHARED_CEPH_FOLDER = "/ceph"

def execute_shell_command_safely(command_string: str, capture_output: bool = True, exit_on_failure: bool = True) -> str:
    print(f"\n[EXEC] {command_string}")
    result = subprocess.run(command_string, shell=True, text=True, capture_output=capture_output)
    if result.returncode != 0 and exit_on_failure:
        print(f"\n[FATAL ERROR] Command failed with exit code {result.returncode}")
        if capture_output:
            print(f"[ERROR OUTPUT]\n{result.stderr.strip()}")
        sys.exit(1)
    return result.stdout.strip() if capture_output else ""

def get_primary_routable_ip_address() -> str:
    temporary_socket = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    try:
        temporary_socket.connect(('10.255.255.255', 1))
        primary_ip = temporary_socket.getsockname()[0]
    except Exception:
        primary_ip = '127.0.0.1'
    finally:
        temporary_socket.close()
    return primary_ip

def prepare_local_cephadm_binary():
    """Locates cephadm within the local shared source directory, sets up bin/, and makes it executable."""
    print("\n=== Phase 2: Preparing Cephadm Binary ===")

    global_target_sbin = "/usr/sbin/cephadm"
    global_target_bin = "/usr/bin/cephadm"

    for target in [global_target_sbin, global_target_bin]:
        if os.path.exists(target):
            try:
                os.remove(target)
            except OSError:
                pass

    cephadm_image = os.environ.get("CEPHADM_IMAGE")

    # extract from the container image
    if cephadm_image and cephadm_image != "None":
        print(f"Extracting cephadm binary directly from container image: {cephadm_image}...")

        with open(global_target_sbin, "w") as out_file:
            extract_result = subprocess.run(
                ["podman", "run", "--rm", "--net=host", "--entrypoint=cat", cephadm_image, "/usr/sbin/cephadm"],
                stdout=out_file,
                text=True
            )

        if extract_result.returncode != 0:
            print(f"\n[FATAL ERROR] Failed to extract cephadm from image {cephadm_image}.")
            sys.exit(1)

        print(f"Successfully extracted cephadm from {cephadm_image}")

    # copy from local shared source directory
    else:
        print("No container image specified. Falling back to local shared source directory...")
        local_cephadm_path = os.path.join(SHARED_CEPH_FOLDER, "src/cephadm/cephadm")

        if not os.path.exists(local_cephadm_path):
            print(f"\n[FATAL ERROR] Local cephadm binary not found at expected path: {local_cephadm_path}")
            sys.exit(1)

        execute_shell_command_safely(f"cp {local_cephadm_path} {global_target_sbin}")
        print(f"Successfully copied local cephadm binary from {local_cephadm_path}")

    execute_shell_command_safely(f"cp {global_target_sbin} {global_target_bin}")
    execute_shell_command_safely(f"chmod +x {global_target_sbin} {global_target_bin}")

    print("Successfully made cephadm binaries executable globally.")

def create_initial_cluster_configuration_file():
    """Generates the initial-ceph.conf file with size-one and deletion overrides."""
    print("\n=== Phase 3: Creating Initial Cluster Config ===")
    config_content = """[global]
osd_pool_default_min_size=1
osd_pool_default_size=1
public_network=172.20.0.0/24

[mon]
mon_allow_pool_size_one=true
mon_allow_pool_delete=true
mon_data_avail_crit=1
mon_data_avail_warn=1
"""
    mgr_configs = []
    prefix = "CONTAINER_IMAGE_"

    for env_key, env_value in os.environ.items():
        # looking for envs like CONTAINER_IMAGE_* that have a value
        if env_key.startswith(prefix) and env_value.strip():
            component_name = env_key[len(prefix):].lower()

            mgr_configs.append(f"mgr/cephadm/container_image_{component_name} = {env_value.strip()}")
            print(f"Found custom image for {component_name}: {env_value.strip()}")

    if mgr_configs:
        config_content += "\n[mgr]\n"
        config_content += "\n".join(mgr_configs) + "\n"

    with open("initial-ceph.conf", "w") as config_file:
        config_file.write(config_content)
    print("Successfully generated initial-ceph.conf")

def load_ceph_image():
    print("\nLoading cached images....")
    tarball_path = "/opt/ceph-image.tar"
    if os.path.exists(tarball_path):
        print(f"Loading pre-bundled image from {tarball_path}...")
        result = subprocess.run(["podman", "load", "-i", tarball_path])
        if result.returncode == 0:
            print("Successfully loaded cached image.")
            return None

    print("No cached images... going to retry on pulling the images..")
    return None

def get_registry_credentials():
    registry_url = os.environ.get("REGISTRY_URL")
    registry_username = os.environ.get("REGISTRY_USERNAME")
    registry_password = os.environ.get("REGISTRY_PASSWORD")

    if not all([registry_url, registry_username, registry_password]):
        print("\n[INFO] Registry credentials not fully provided. Skipping login.")
        return ""

    return f" --registry-url {registry_url} --registry-username {registry_username} --registry-password {registry_password}"

def bootstrap_initial_ceph_cluster(monitor_ip_address: str):
    print(f"\n=== Phase 3: Bootstrapping Cluster on {monitor_ip_address} ===")
    custom_image = os.environ.get("CEPHADM_IMAGE")
    shared_repo_toggle = os.environ.get("SHARED_CEPH_REPO_DIR", "0")

    shared_repo_flag = "--shared_ceph_folder /ceph " if shared_repo_toggle == "1" else ""
    image_flag = f"--image {custom_image} " if custom_image else ""

    bootstrap_command = (
        f"yes \"yes\" | cephadm {image_flag}bootstrap "
        f"--mon-ip {monitor_ip_address} "
        f"--allow-overwrite "
        f"--skip-mon-network "
        f"--config initial-ceph.conf "
        f"--dashboard-password-noupdate "
        f"{shared_repo_flag}"
        f"--initial-dashboard-password admin "
        f"--allow-fqdn-hostname"
        f"{get_registry_credentials()}"
    ).strip()
    execute_shell_command_safely(bootstrap_command, capture_output=False)

def initialize_cephalobox():
    monitor_ip_address = get_primary_routable_ip_address()
    load_ceph_image()
    prepare_local_cephadm_binary()
    create_initial_cluster_configuration_file()

    bootstrap_initial_ceph_cluster(monitor_ip_address)
    
    print("\nCephalabox has done its job!!!!")


if __name__ == '__main__':
    initialize_cephalobox()
