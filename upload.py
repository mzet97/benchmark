#!/usr/bin/env python3
"""Upload a local file to a remote path via SFTP."""
import sys
import paramiko

def upload(local_path, remote_path):
    client = paramiko.SSHClient()
    client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    client.connect('192.168.1.51', username='k8s1', password='Admin@123', timeout=15)
    sftp = client.open_sftp()
    sftp.put(local_path, remote_path)
    sftp.close()
    client.close()
    print(f"Uploaded {local_path} -> {remote_path}")

if __name__ == '__main__':
    upload(sys.argv[1], sys.argv[2])
