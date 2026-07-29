#!/usr/bin/env python3
"""Write content to a file on remote server via SFTP."""
import sys
import paramiko

def sftp_write(host, user, password, remote_path, content):
    client = paramiko.SSHClient()
    client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    client.connect(host, username=user, password=password, timeout=15)
    sftp = client.open_sftp()
    with sftp.open(remote_path, 'w') as f:
        f.write(content)
    sftp.close()
    client.close()
    print(f"Written {len(content)} bytes to {remote_path}")

if __name__ == '__main__':
    remote_path = sys.argv[1]
    content = sys.stdin.read()
    sftp_write('192.168.1.51', 'k8s1', 'Admin@123', remote_path, content)
