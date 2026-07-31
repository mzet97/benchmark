#!/usr/bin/env python3
import os
import sys
import paramiko

def ssh_exec(host, user, password, cmd):
    client = paramiko.SSHClient()
    client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    client.connect(host, username=user, password=password, timeout=15)
    stdin, stdout, stderr = client.exec_command(cmd, timeout=120)
    out = stdout.read().decode('utf-8', errors='replace')
    err = stderr.read().decode('utf-8', errors='replace')
    code = stdout.channel.recv_exit_status()
    client.close()
    if out:
        print(out, end='')
    if err:
        print(err, end='', file=sys.stderr)
    return code

if __name__ == '__main__':
    cmd = ' '.join(sys.argv[1:])
    code = ssh_exec('192.168.1.51', 'k8s1', os.environ["K3S_SSH_PASSWORD"], cmd)
    sys.exit(code)
