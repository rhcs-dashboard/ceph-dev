#!/usr/bin/env python3
import os
import sys
import subprocess
import socket
import time

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

def remove_systemctl_time_sync_spoof():
    if os.path.exists("/usr/bin/systemctl.real"):
        execute_shell_command_safely("mv /usr/bin/systemctl.real /usr/bin/systemctl")

def prepare_local_cephadm_binary():
    """Locates cephadm within the local shared source directory, sets up bin/, and makes it executable."""
    print("\n=== Phase 2: Preparing Local Cephadm Binary ===")
    local_cephadm_path = os.path.join(SHARED_CEPH_FOLDER, "src/cephadm/cephadm")
    
    if not os.path.exists(local_cephadm_path):
        print(f"\n[FATAL ERROR] Local cephadm binary not found at expected path: {local_cephadm_path}")
        print("Please verify that your source code folder is properly mounted at /ceph-dir.")
        sys.exit(1)
        
    os.makedirs("bin", exist_ok=True)
    bin_cephadm_target = os.path.join("bin", "cephadm")
    
    for target in [bin_cephadm_target, "./cephadm"]:
        if os.path.exists(target):
            os.remove(target)
            
    # Copy local source binary to bin/ and root execution path
    execute_shell_command_safely(f"cp {local_cephadm_path} {bin_cephadm_target}")
    execute_shell_command_safely(f"cp {local_cephadm_path} ./cephadm")
    execute_shell_command_safely("chmod +x bin/cephadm ./cephadm")
    print(f"Successfully configured local cephadm binary from {local_cephadm_path} into bin/ and root.")

def create_initial_cluster_configuration_file():
    """Generates the initial-ceph.conf file with size-one and deletion overrides."""
    print("\n=== Phase 3: Creating Initial Cluster Config ===")
    config_content = """[global]
osd_pool_default_min_size=1
osd_pool_default_size=1

[mon]
mon_allow_pool_size_one=true
mon_allow_pool_delete=true
mon_data_avail_crit=1
mon_data_avail_warn=1
"""
    with open("initial-ceph.conf", "w") as config_file:
        config_file.write(config_content)
    print("Successfully generated initial-ceph.conf")

def load_ceph_image():
    print("\nLoading cached images....")
    
    custom_image = os.environ.get("CEPH_IMAGE")
    if custom_image:
        print(f"Detected custom image: {custom_image}")
        print(f"Pulling custom image: {custom_image}...")
        result = subprocess.run(["podman", "pull", custom_image])
        if result.returncode == 0:
            print(f"Successfully pulled custom image: {custom_image}")
            return custom_image
        else:
            print(f"Failed to pull custom image {custom_image}. Falling back...")

    tarball_path = "/opt/ceph-image.tar"
    if os.path.exists(tarball_path):
        print(f"Loading pre-bundled image from {tarball_path}...")
        result = subprocess.run(["podman", "load", "-i", tarball_path])
        if result.returncode == 0:
            print("Successfully loaded cached image.")
            return None
            
    print("No cached images... going to retry on pulling the images..")
    return None

def bootstrap_initial_ceph_cluster(monitor_ip_address: str):
    print(f"\n=== Phase 3: Bootstrapping Cluster on {monitor_ip_address} ===")
    custom_image = os.environ.get("CEPH_IMAGE")
    image_flag = f"--image {custom_image} " if custom_image else ""
    bootstrap_command = (
        f"./cephadm {image_flag}bootstrap "
        f"--mon-ip {monitor_ip_address} "
        f"--allow-overwrite "
        f"--skip-mon-network "
        f"--config initial-ceph.conf "
        f"--dashboard-password-noupdate "
        f"--shared_ceph_folder /ceph "
        f"--initial-dashboard-password admin "
        f"--allow-fqdn-hostname"
    )
    execute_shell_command_safely(bootstrap_command, capture_output=False)

def initialize_cephalobox():
    monitor_ip_address = get_primary_routable_ip_address()
    prepare_local_cephadm_binary()
    create_initial_cluster_configuration_file()

    load_ceph_image()

    bootstrap_initial_ceph_cluster(monitor_ip_address)
    remove_systemctl_time_sync_spoof()
    
    print("\nCephalabox has done its job!!!!")


if __name__ == '__main__':
    initialize_cephalobox()
