#!/usr/bin/env python3
"""Write content to remote file via SSH using base64 encoding."""
import sys
import paramiko
import base64
import tempfile
import os

def ssh_write_file(host, user, password, remote_path, content):
    client = paramiko.SSHClient()
    client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    client.connect(host, username=user, password=password, timeout=15)

    # Use base64 to safely transfer any content
    # Split into chunks to avoid command line length limits
    encoded = base64.b64encode(content.encode('utf-8')).decode('ascii')

    # Write in chunks of 4096 chars
    chunk_size = 4096
    first = True
    for i in range(0, len(encoded), chunk_size):
        chunk = encoded[i:i+chunk_size]
        if first:
            cmd = f'echo -n "{chunk}" | base64 -d > "{remote_path}"'
            first = False
        else:
            cmd = f'echo -n "{chunk}" | base64 -d >> "{remote_path}"'
        stdin, stdout, stderr = client.exec_command(cmd, timeout=30)
        exit_code = stdout.channel.recv_exit_status()
        if exit_code != 0:
            err = stderr.read().decode()
            print(f"ERROR (exit {exit_code}): {err}", file=sys.stderr)
            client.close()
            sys.exit(1)

    client.close()
    print(f"OK: wrote {len(content)} bytes to {remote_path}")

if __name__ == '__main__':
    if len(sys.argv) < 3:
        print(f"Usage: {sys.argv[0]} <local_path> <remote_path>")
        sys.exit(1)
    local_path = sys.argv[1]
    remote_path = sys.argv[2]
    with open(local_path, 'r', encoding='utf-8') as f:
        content = f.read()
    ssh_write_file('192.168.1.51', 'k8s1', 'Admin@123', remote_path, content)
