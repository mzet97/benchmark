#!/usr/bin/env python3
"""Upload a local file to remote server via SFTP."""
import sys
import os
import paramiko

def upload(local_path, remote_path):
    # Resolve the local path
    local_path = os.path.abspath(local_path)
    if not os.path.exists(local_path):
        print(f"ERROR: Local file not found: {local_path}")
        sys.exit(1)

    client = paramiko.SSHClient()
    client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    client.connect('192.168.1.51', username='k8s1', password=os.environ["K3S_SSH_PASSWORD"], timeout=15)
    sftp = client.open_sftp()
    sftp.put(local_path, remote_path)
    sftp.close()
    client.close()
    print(f"OK: {local_path} -> {remote_path}")

if __name__ == '__main__':
    if len(sys.argv) != 3:
        print(f"Usage: {sys.argv[0]} <local_path> <remote_path>")
        sys.exit(1)
    upload(sys.argv[1], sys.argv[2])
