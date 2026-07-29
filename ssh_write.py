#!/usr/bin/env python3
"""Write content to remote file via SSH."""
import sys
import paramiko
import base64

def ssh_write(host, user, password, remote_path, local_path):
    with open(local_path, 'r', encoding='utf-8') as f:
        content = f.read()

    client = paramiko.SSHClient()
    client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    client.connect(host, username=user, password=password, timeout=15)

    # Use base64 to safely transfer any content
    encoded = base64.b64encode(content.encode('utf-8')).decode('ascii')
    cmd = f'echo "{encoded}" | base64 -d > "{remote_path}"'
    stdin, stdout, stderr = client.exec_command(cmd, timeout=30)
    exit_code = stdout.channel.recv_exit_status()
    client.close()

    if exit_code == 0:
        print(f"OK: wrote {len(content)} bytes to {remote_path}")
    else:
        err = stderr.read().decode()
        print(f"ERROR (exit {exit_code}): {err}", file=sys.stderr)
        sys.exit(1)

if __name__ == '__main__':
    if len(sys.argv) != 3:
        print(f"Usage: {sys.argv[0]} <local_path> <remote_path>")
        sys.exit(1)
    ssh_write('192.168.1.51', 'k8s1', 'Admin@123', sys.argv[2], sys.argv[1])
